#!/usr/bin/env ruby
# vim: set shiftwidth=2 tabstop=2 expandtab:
# encoding: utf-8

require 'optparse'
require 'ostruct'
require 'mssql/helpers/filereader'

# command line options parser class
module MSSQL
  module Script
    class NormalizerOptions < OptionParser
      attr_reader :options

      def initialize(args)
        super()
        @options = OpenStruct.new
        @options.file = '.'
        @options.mask = '*.TAB.sql'
        @options.verbose = false
        @options.trailing_spaces = false
        @options.go = false
        @options.output = nil

        separator ""
        separator "Options:"

        init
        parse!(args)
        validate
      end

    private
      def init
        on("-i", "--file FILE",
            "File or directory") do |f|
          @options.file = f
        end

        on("-m", "--mask [MASK]",
            "File mask") do |m|
          @options.mask = m
        end

        on("-g", "--go",
            "Normalize GO keyword") do |t|
          @options.go = true
        end

        on('-o', '--output FILE',
            'Output file or directory (corresponding to input)') do |out|
          @options.output = out
        end

        on("-t", "--trailing-spaces",
            "Remove trailing spaces") do |t|
          @options.trailing_spaces = true
        end

        on("-v", "--verbose",
            "Verbose") do |m|
          @options.verbose = true
        end

        # No argument, shows at tail.  This will print an options summary.
        # Try it and see!
        on_tail("-h", "--help", "Show this message") do
          puts self
          exit
        end
      end  # init

      def validate
            if @options.output
                if File.directory?(@options.file) && !File.directory?(@options.output) \
                        || !File.directory?(@options.file) && File.directory?(@options.output)
                    raise 'Output and input must be both the same type: FILE or DIRECTORY'
                end
            end
      end

    end  # class NormalizerOptions

    class Elements < ::Array
      def << (value)
        value.index = size
        super
      end
    end

    class Element
      attr_accessor :index, :lines
      @@classes = []

      def self.find_sql_classes
        return @@classes unless @@classes.empty?
        MSSQL::Script.constants.each do |const|
          klass = MSSQL::Script.const_get(const)
          next unless klass.is_a?(Class)
          @@classes << klass if klass <= Element
        end
        # sort classes to be sure that Element successor classes will match hunk before the Element
        @@classes.sort! do |a, b|
          a.priority <=> b.priority
        end
        return @@classes
      end

      def self.priority
        # priority is calculated with a name
        # for Element descendants we use their class names
        return name if self < Element
        # but the Element (ancestor) must be the last
        # ZZZZ class name is almost impossible so it will be the last when sort by name
        return 'ZZZZ'
      end

      def self.getnew(lines)
        find_sql_classes.each do |klass|
          next unless klass.method_defined?('sql_valid?')
          instance = klass.new(lines)
          return instance if instance.type && instance.sql_valid?
          instance = nil
        end
        nil
      end

      def initialize(lines)
        @lines = lines
        @index = -1
        @name = self.class.name
      end

      def doCompare(compared)
        index <=> compared.index
      end

      def compare(compared)
        raise "Incompatible types for compare (#{self.class.name} && #{compared.class.name})" unless self.class.name == compared.class.name
        doCompare(compared)
      end

      def sql_valid?
        # valid for any sql (but be sure it will match hunk when there are no other classes remained to match)
        # see self.find_sql_classes and self.priority
        true
      end

      def type
        return 'unknown'
      end

      def name
        @name
      end
    end

    class OneLineElement < Element
      def type
        # skip class autodetection
        # successors must be detected
        return nil
      end

      def mainRE
        raise 'Override'
      end

      def setName(match)
        @name = match[0]
      end

      def doCompare(compared)
        name <=> compared.name
      end

      def sql_valid?
        @lines.each do |line|
          if m = mainRE.match(line)
            setName(m)
            return true
          end
        end
        return false
      end
    end

    class Index < OneLineElement
      def type
        return 'index'
      end

      def mainRE
        return /^\s*CREATE\s+(UNIQUE\s+)?INDEX\s*\[([^\]]+)\]/
      end

      def setName(match)
        @name = match[2]
      end
    end

    class DropConstraint < OneLineElement
      def type
        return 'drop constraint'
      end

      def mainRE
        return /^\s*ALTER\s+TABLE\s+.+?\bDROP\s+CONSTRAINT\b/
      end

      def doCompare(compared)
        index <=> compared.index
      end
    end

    class MultiStringElement < OneLineElement
      def nameRE
        raise 'Override'
      end

      def setName(match)
        raise 'Override'
      end

      def sql_valid?
        r = false
        @lines.each do |line|
          if m = mainRE.match(line)
            r = true
          end
          if r && m = nameRE.match(line)
            setName(m)
            return true
          end
        end
        return false
      end
    end

    class ExtendedProperty < MultiStringElement
      def type
        return 'extended property'
      end

      def mainRE
        return /^\s*exec\s+sp_addextendedproperty\b/i
      end

      def nameRE
        return /N'table',\s+N'(\w+)'(,\s+N'column',\s+N'(\w+)')?/i
      end

      def setName(match)
        @name = match[1] + '_' + match[3].to_s
      end
    end

    class Constraint < MultiStringElement
      def mainRE
        return /^\s*ALTER\s+TABLE\b.+?WITH\s+(NO)?CHECK\s+ADD\b/i
      end

      def constraintType
        raise "Override"
      end

      def nameRE
        return /^\s*CONSTRAINT\s+\[([^\]]+)\]\s+#{constraintType}\b/i
      end

      def setName(match)
        @name = match[1]
      end
    end

    class UniqueConstraintIndex < Constraint
      def type
        return 'unique constraint index'
      end

      def constraintType
        return 'UNIQUE\s+NONCLUSTERED'
      end
    end

    class Default < Constraint
      def type
        return 'default'
      end

      def constraintType
        return 'DEFAULT'
      end
    end

    class ForeignKey < Constraint
      def type
        return 'foreign key'
      end

      def constraintType
        return 'FOREIGN\s+KEY'
      end
    end

    class SQLFile
      def initialize(file)
        @file = file
        @elements = Elements.new
        readfile
        if block_given?
          yield self
        else
          sort
        end
      end

      def readfile
        @contents = FileReader.readlines(@file)
        hunk = []
        @contents.each do |line|
          hunk << line
          if /^GO\b/.match(line)
            el = Element.getnew(hunk)
            @elements << el if el
            hunk = []
          end
        end
      end

      def sort
        @elements.sort! do |a, b|
          if a.type == b.type
            # sort only the same types
            a.compare(b)
          else
            # otherwise use default order
            a.index <=> b.index
          end
        end
      end

      def remove_trailing_spaces
        @elements.collect! do |el|
          el.lines.collect! do |line|
            line.gsub(/ +(?=\r?\n)/, '')
          end
          el
        end
      end

      def remove_empty_lines(lines)
        b = true
        # remove first empty lines
        lines.reject! do |line|
          if b && line.gsub(/^\s*$/, '').empty?
            true
          else
            b = false
          end
        end
        return lines
      end

      def normalize_go
        # take into account Ruby platform
        # to avoid incorrect behaviour:
        #   "\n" on Windows is CRLF, not LF (as on Linux/Cygwin)
        eol = (RUBY_PLATFORM !~ /mingw|mswin/ ? "\r" : '') + "\n"
        @elements.collect! do |el|
          # remove empty lines at the beginning
          remove_empty_lines(el.lines)
          # remove empty lines before GO:
          #   pop GO
          go = el.lines.reverse!.shift
          #   remove empty lines before it
          remove_empty_lines(el.lines)
          #   and push it back
          el.lines.reverse! << go
          # add empty line after GO
          el.lines << eol
          el
        end
      end

      def filter(lines)
        # redefine this method to reach your goals
        return lines
      end

      def to_s
        r = []
        @elements.each do |el|
          r << el.lines
        end
        # we can filter contents (usually before saving to a file)
        r = filter(r.flatten)
        return r.join
      end

      def save(output)
        if ! output
          output = @file
        elsif File.directory?(output)
          # save with the same name to directory output
          output = File.expand_path(File.basename(@file), output)
        end
        File.open(output, 'w') do |f|
          f.write(self.to_s)
        end
      end
    end

    class Normalizer
      def initialize(opt)
        @opt = opt.options
      end

      def run
        if File.directory?(@opt.file)
          d = Dir[@opt.file + '/' + @opt.mask]
        else
          d = [@opt.file]
        end
        d.each do |file|
          processfile(file, @opt.output)
        end
      end

      def processfile(file, output)
        SQLFile.new(file) do |f|
          puts file if @opt.verbose
          f.sort
          f.remove_trailing_spaces if @opt.trailing_spaces
          f.normalize_go if @opt.go
          f.save(output)
        end
      end
    end # class Normalizer
  end # module Script
end # module MSSQL
