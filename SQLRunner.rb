#!/usr/bin/env ruby
# vim: set shiftwidth=2 tabstop=2 expandtab:
# encoding: utf-8

require 'optparse'
require 'ostruct'
require 'stringio'

module Log
  SILENT = 0
  INFO = 1
  WARN = 2
  DEBUG = 3
end

module ADO
  ADStateClosed = 0 # The object is closed
  ADStateOpen =1  # The object is open
  ADStateConnecting = 2 # The object is connecting
  ADStateExecuting = 4  # The object is executing a command
  ADStateFetching = 8 # The rows of the object are being retrieved
end

# command line options parser class
class SQLTCmdLine < OptionParser
  attr_reader :options, :debug, :verbose, :concat, :run,
    :getVersion, :incVersion, :decVersion

  def initialize(args)
    super()
    @options = OpenStruct.new
    @options.host = \
    @options.db = \
    @options.user = \
    @options.pass = \
    @options.output = \
    @options.query = \
    @options.file = ""
    @options.rollback = false
    @options.time = false
    @options.level = Log::INFO
    @options.log = nil
    @options.inputs = []

    separator ""
    separator "Options:"

    init
    parse!(args)
    validate
  end

private
  def init
    on("-H", "--host HOST",
      "Hostname") do |h|
      @options.host = h
    end

    on("-d", "--database DATABASE",
        "Database name") do |db|
      @options.db = db
    end

    on("-u", "--user USER:PASS",
        "Username:password") do |user|
      @options.user, @options.pass = user.split(':')
    end

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

    on("-q", "--quiet",
        "Quiet mode") do
      @level = Log::SILENT
    end

    on("-Q", "--query [QUERY]",
        "Query string") do |q|
      @options.query = q
      @options.inputs << StringIO.new(q)
    end

    on("-D", "--debug",
        "Debug mode") do
      @options.level = Log::DEBUG
    end

    # No argument, shows at tail.  This will print an options summary.
    # Try it and see!
    on_tail("-h", "--help", "Show this message") do
      puts self
      exit
    end
  end  # parseargs()

  def validate
    @options.host = 'localhost' if @options.host.empty?
    @options.db = 'test' if @options.db.empty?
  end

end  # class SQLTCmdLine

class TScriptRunner
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

  def getUser
    return @opt.options.user.to_s.empty? ? "trusted" : @opt.options.user
  end

  def indicate
    return [@opt.options.host, ".", @opt.options.db, "@", getUser()].join
  end

  def getConnectionStr
    if @opt.options.user.to_s.empty?
      s = "Trusted_Connection=Yes"
    else
      s = "UID=%s;PWD=%s;" % [@opt.options.user, @opt.options.pass]
    end
    s = "Provider=SQLOLEDB;Data Source=%s;Initial Catalog=%s;%s" % \
      [@opt.options.host, @opt.options.db, s]
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

# if run directly (not a module)
if __FILE__ == $0
  cmdLine = SQLTCmdLine.new(ARGV.dup)
  ScriptRunner = TScriptRunner.new(cmdLine)
  exit ScriptRunner.run()
end
