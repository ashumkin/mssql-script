#!/usr/bin/env ruby
# vim: set shiftwidth=2 tabstop=2 expandtab:
# encoding: utf-8

require 'test/unit'
require 'stringio'
require 'mssql/script/normalizer'
require 'rake'
require 'unixdiff'

# Ruby 1.9 uses "minitest". There is no `name` property there
module Test
  module Unit
    class TestCase
      def name
        __name__
      end unless TestCase.instance_methods.include?(:name) || TestCase.instance_methods.include?('name')
    end
  end
end

module MSSQL
  module Script

    # define a filter to replace datetime2 to datetime2(3)
    class SQLFile
      def filter(lines)
        # filter Tables only
        return lines unless is_type?(Table)
        regex = /\[?datetime2\]?(?![\(\]])/
        lines.map! do |line|
          comments = line.index(/--/)
          if comments.nil? || line.index(regex).to_i < comments
            line.gsub!(regex, '\0(3)')
          end
          line
        end
      end
    end

    class TestNormalizer < Test::Unit::TestCase
    private
      def assert_equal_text(expected, actual, file)
        diff = expected.diff(actual)
        oldoutput = $>
        begin
          $> = diff_text = StringIO.new('')
          diff.to_diff
        ensure
          $> = oldoutput
        end
        assert_equal(true, diff.diffs.empty?, file + ': ' + diff_text.string)
      end

      def clear_output_dir(dir)
        # clear output
        filelist = FileList[dir + '/*']
        filelist.each do |f|
          FileUtils.rm(f)
        end
      end

      def _test_files(dir, mask, filelist = nil)
        @args << '--mask' << (filelist || mask)
        @opts = NormalizerOptions.new(@args)
        @sqlNormalizer = Normalizer.new(@opts)

        clear_output_dir(@opts.options.output)
        @sqlNormalizer.run
        c = 0
        filelist = FileList[File.expand_path('../resources/source/' + mask, __FILE__)]
        filelist.each do |f|
          c += 1
          f_name = File.basename(f)
          f_actual = File.expand_path(f_name, @opts.options.output)
          # for particular files
          # source is untouched
          if filelist
            FileUtils.cp(f, f_actual) unless File.exists?(f_actual)
          end
          f_expected = File.expand_path(f_name, File.expand_path("../resources/expected/#{dir}/" , __FILE__))
          test_text_output = FileReader.readlines(f_actual)
          test_text_expected = FileReader.readlines(f_expected)
          assert_equal_text(test_text_expected, test_text_output, f_name)
        end
        assert_not_equal(0, c, 'Source files count = 0')
      end

    public
      def setup
        @args = ['--file', File.expand_path('../resources/source/', __FILE__)]
        @args << '--go'
        @args << '--trailing-spaces' if /tables/.match(name)
        @args << '--output' << File.expand_path('../resources/output/', __FILE__)
      end

      def test_tables
        _test_files('all', '*.TAB.sql')
      end

      def test_tables_particular_files
        _test_files('particular',  '*.TAB.sql', 'a2_Addition.TAB.sql,b_ContractorsAddInfo.TAB.sql')
      end

      def test_procedures
        _test_files('all', '*.PRC.sql')
      end

      def test_procedures_particular_files
        _test_files('particular',  '*.PRC.sql', 'AddResponsibles.PRC.sql')
      end

    end

  end # module Script
end # module MSSQL

