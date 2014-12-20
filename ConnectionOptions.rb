require 'optparse'
require 'ostruct'

module Log
  SILENT = 0
  WARN = 1
  INFO = 2
  DEBUG = 3
end

module SQL

# command line options parser class
class TConnectionCmdLine < OptionParser
  attr_reader :options, :debug

  def initialize(args)
    super()
    init_options
    init
    parse!(args)
    validate
  end

  def init_options
    @options = OpenStruct.new
    @options.host = \
    @options.db = \
    @options.user = \
    @options.pass = ''
    @options.level = Log::WARN
    @options.log = nil

    separator ""
    separator "Options:"
  end

  def log(level, msg)
    if @options.level >= level
      $stderr.puts msg
    end
  end

  def verbose
    @level >= Log::WARN
  end

  def indicate
    return [@options.host, ".", @options.db, "@", getUser()].join
  end

  def getConnectionStr
    if @options.user.empty?
      s = "Trusted_Connection=Yes"
    else
      s = "UID=%s;PWD=%s" % [@options.user, @options.pass]
    end
    s = "Provider=SQLOLEDB;Data Source=%s;Initial Catalog=%s;%s" % [@options.host, @options.db, s]
  end

  def init
    on('-H', '--host HOST', 'Hostname') do |h|
      @options.host = h
    end

    on('-d', '--database DATABASE', 'Database name') do |db|
      @options.db = db
    end

    on('-u', '--user USER:PASS', 'Username:password') do |user|
      @options.user, @options.pass = user.split(':')
    end

    on('-q', '--quiet', 'Quiet mode') do
      @level = Log::SILENT
    end

    on('-D', '--debug', 'Debug mode') do
      @options.level = Log::DEBUG
    end

    # No argument, shows at tail.  This will print an options summary.
    # Try it and see!
    on_tail('-h', '--help', 'Show this message') do
      $stderr.puts help
      exit
    end
  end  # parseargs()

  def validate
    @options.host = 'localhost' if @options.host.empty?
    @options.user = @options.user.to_s
    @options.pass = @options.pass.to_s
    if @options.db.empty?
      $stderr.puts 'DB is not defined' if @options.db.empty?
      $stderr.puts help
      exit
    end
  end

  def getUser
    return @options.user.empty? ? 'trusted' : @options.user
  end
end  # class TConnectionCmdLine

end # module SQL
