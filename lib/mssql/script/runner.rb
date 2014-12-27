#!/usr/bin/env ruby
# vim: set shiftwidth=2 tabstop=2 expandtab:
# encoding: utf-8

require 'mssql/ado/constants'
require 'mssql/script/connection_options'
require 'stringio'

# command line options parser class
module MSSQL

module Script

class RunnerOptions < TConnectionCmdLine
  attr_reader :run

  def init_options
    super
    @options.output = \
    @options.query = \
    @options.file = ""
    @options.rollback = false
    @options.time = false
    @options.inputs = []
  end

  def init
    super

    on("-o", "--output DIR",
        "Output directory") do |dir|
      @options.output = dir
    end

    on("-i", "--file [FILE]",
        "File") do |f|
      @options.file = f
      @options.inputs << f
    end

    on("-L", "--log [FILE]",
        "File") do |f|
      @options.log = f
    end

    on("-r", "--rollback",
        "rollback script") do
      @options.rollback = true
    end

    on("-t", "--time",
        "Count execution time") do
      @options.time = true
    end

    on("-Q", "--query [QUERY]",
        "Query string") do |q|
      @options.query = q
      @options.inputs << StringIO.new(q)
    end

  end  # init
end  # class RunnerOptions

class Runner
  attr_accessor :level, :error

  def initialize(opt)
    super()
    @opt = opt
    @error = ''
    @level = @opt.options.level
  end

  def openlog(input)
    log = @opt.options.log
    if log == '-'
      @log = STDOUT
    else
      log = input.to_s + '.log' if log.nil?
      begin
        @log = File.open(log, 'w')
      rescue
        @log = STDOUT
        log("Failed to open for writing file #{log}")
      end
    end
  end

  def indicate
    return @opt.indicate
  end

  def getConnectionStr
    return @opt.getConnectionStr
  end

  def run(file = nil)
    @opt.options.inputs << file if file
    openlog(file)
    getDBVersion
    return runinputs
  end

  def log(msg, level = Log::INFO)
    if @level >= level
      @log.write(msg + "\n")
    end
  end

  def getDBVersion
    log(indicate)
    log(getConnectionStr(), Log::DEBUG)
    log("Getting version...", Log::DEBUG)
    require 'win32ole'
    # setting codepage has a reason on Ruby 1.9.x
    WIN32OLE.codepage = WIN32OLE::CP_ACP if RUBY_VERSION !~ /^1\.8/
    @objConnection = WIN32OLE.new("ADODB.Connection")
    @objRecordSet = WIN32OLE.new("ADODB.Recordset")
    @objConnection.Open(getConnectionStr)
    @objRecordSet.Open("SELECT @@Version", @objConnection)
    useRecordSet(@objRecordSet)
  end

  def useRecordSet(recordSet)
    log('RecordSet state = ' + recordSet.State.to_s, Log::DEBUG)
    if recordSet.State == ADO::ADStateOpen
      begin
        while !recordSet.EOF
          # it seems GetString moves record pointer to next record
          log(recordSet.GetString, Log::WARN)
        end
      # Nota bene: NextRecordSet closes currect recordset
      end while recordSet = recordSet.NextRecordSet
    end
  end

  def usehunk(hunk)
    log(hunk, Log::DEBUG)
    begin
      @objRecordSet.Open(hunk, @objConnection)
      useRecordSet(@objRecordSet)
      log('[ Ok ]', Log::DEBUG)
    rescue Exception => e
      log('[ Error ] ' + e.message, Log::DEBUG)
      @error = e.message
      return false
    end
    return true
  end

  def runinputs
    @opt.options.inputs.each do |i|
      return false unless runinput(i)
    end
    return true
  end

  def runinput(input)
    if input.kind_of?(String) \
      && (input.to_s.empty? \
        || input == '-')
      input = STDIN
    elsif ! input.kind_of?(StringIO)
      input = File.open(input, 'r')
    end
    @objConnection.BeginTrans
    commentStarted = false
    hunk = ''
    r = true
    while (os = input.gets)
      line = os.chomp
      if line[1..2] == '/*'
        # if comment is not in script body
        commentStarted = hunk.chomp.empty?
        # but if comment is oneliner
        if line.index('*/') > 2 then
          commentStarted = false
        end
      elsif commentStarted and line[1..2] = '*/'
        commentStarted = false
        next
      end
      if commentStarted ||
          line.start_with?('SET QUOTED_IDENTIFIER')
        next
      elsif line.casecmp('GO') != 0
        hunk += line + "\n"
      else # if GO
        next if hunk.chomp.empty?
        r = usehunk(hunk)
        hunk = ''
        # exit if error
        break if !r
      end
    end
    r = usehunk(hunk) unless hunk.chomp.empty?
    if @opt.options.rollback || !r
      @objConnection.RollbackTrans
      if !r
        log('rolled back due to error', Log::WARN)
      else
        log('rolled back due to --rollback', Log::WARN)
      end
    else
      @objConnection.CommitTrans
    end
    return r
  end;
end # class TScriptRunner

end # module Script

end # module MSSQL
