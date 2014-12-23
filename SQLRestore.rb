#!/usr/bin/env ruby

require File.expand_path('../ConnectionOptions', __FILE__)
require File.expand_path('../File.rb', __FILE__)

module SQL

module ADO
  ADStateClosed = 0 # The object is closed
  ADStateOpen =1  # The object is open
  ADStateConnecting = 2 # The object is connecting
  ADStateExecuting = 4  # The object is executing a command
  ADStateFetching = 8 # The rows of the object are being retrieved

  ADOpenForwardOnly = 0
  ADOpenKeyset = 1
  ADOpenDynamic = 2
  ADOpenStatic = 3
end


# command line options parser class
class RestorerOptions < TConnectionCmdLine
  def init_options
    super
    @options.file = ''
    @options.restore_path = ''
    @options.restore_as = ''
    # 5 minutes of a restore is enough?
    @options.timeout = 300
  end

  def validate_error(msg)
      $stderr.puts msg
      $stderr.puts help
      exit 1
  end
  def validate
    super
    if @options.restore_as.empty?
      validate_error('Restore DB name is not defined')
    end
    if @options.restore_path.empty?
      validate_error('Restore path is not defined')
    end
    if @options.file.empty?
      validate_error( 'Input file is not defined')
    else
      @options.file = File.expand_path2(@options.file)
    end
  end

  def init
    super
    on('-i', '--file FILE', 'Backup file') do |f|
      @options.file = f
    end

    on('-L', '--list-only', 'List backup content info') do |l|
      @options.list_only = l
    end

    on('-P', '--path PATH', 'Restore DB path') do |p|
      @options.restore_path = File.expand_path2(p)
    end

    on('-R', '--restore-as NAME', 'Restore DB name') do |name|
      @options.restore_as = name
    end

    on('-t', '--timeout', 'Restore process timeout') do |t|
      @options.timeout = t
    end

  end
end # class RestoratorOptions

class Restorer
  def initialize(cmdLine)
    @cmdLine = cmdLine
  end

  def run
    initADO
    list_files
    do_restore
  end

  def initADO
    require 'win32ole'
    # setting codepage has a reason on Ruby 1.9.x
    WIN32OLE.codepage = WIN32OLE::CP_ACP if RUBY_VERSION !~ /^1\.8/
    @objConnection = WIN32OLE.new('ADODB.Connection')
    @objRecordSet = WIN32OLE.new('ADODB.Recordset')
    @objConnection.Open(@cmdLine.getConnectionStr)
    @objRecordSet.Open('SELECT @@Version', @objConnection)
    useRecordSet(@objRecordSet)
  end

  def log(level, msg)
    @cmdLine.log(level, msg)
  end

  def useRecordSet(recordSet, level = Log::WARN)
    log(Log::DEBUG, 'RecordSet state = ' + recordSet.State.to_s)
    if recordSet.State == ADO::ADStateOpen
      begin
        while !recordSet.EOF
          # it seems GetString moves record pointer to next record
          log(level, recordSet.GetString)
        end
      # Nota bene: NextRecordSet closes currect recordset
      end while recordSet = recordSet.NextRecordSet
    end
  end

  def print_recordset(recordset, fields, level)
    if fields == '*'
      fields = []
      recordset.Fields.Count.times.each do |i|
        fields << recordset.Fields.Item(i).Name
      end
    end
    log(level, fields.join(' '))
    while !recordset.EOF
      a = []
      fields.each do |field|
        a << recordset.Fields.Item(field).Value
      end
      yield recordset if block_given?
      log(level, a.join(' '))
      recordset.MoveNext
    end
    log(level, '')
  end

  def list_files
    @objRecordSet.Open("RESTORE LABELONLY FROM DISK = N'#{@cmdLine.options.file}' WITH NOUNLOAD", @objConnection)
    #print_recordset(@objRecordSet, '*', Log::WARN)
    softwareName = @objRecordSet.Fields.Item('SoftwareName').Value
    useRecordSet(@objRecordSet, Log::DEBUG)
    log(Log::WARN, softwareName)

    @objRecordSet.Open("RESTORE HEADERONLY FROM DISK = N'#{@cmdLine.options.file}' WITH NOUNLOAD", @objConnection, -1)
    @file_position = 0
    print_recordset(@objRecordSet, ['Position', 'DatabaseVersion', 'SoftwareVendorId', 'CompatibilityLevel', 'SoftwareVersionMajor', 'SoftwareVersionMinor', 'SoftwareVersionBuild'], Log::WARN) do |rs|
      @file_position = rs.Fields.Item('Position').Value if rs.Fields.Item('Position').Value > @file_position
    end
    useRecordSet(@objRecordSet)

    @db_files = {}
    @objRecordSet.Open("RESTORE FILELISTONLY FROM DISK = N'#{@cmdLine.options.file}' WITH FILE=#{@file_position}", @objConnection)
    print_recordset(@objRecordSet, ['Type', 'LogicalName', 'PhysicalName', 'Size'], Log::WARN) do |rs|
      @db_files[rs.Fields.Item('LogicalName').Value] = rs.Fields.Item('Type').Value
    end
    useRecordSet(@objRecordSet)
  end

  def do_restore
    return if @cmdLine.options.list_only
    move = []
    @db_files.each do |file, type|
      name = @cmdLine.options.restore_as + (type == 'D' ? '.mdf' : '_log.ldf')
      move << "MOVE N'%s' TO '%s\\%s'" % [file, @cmdLine.options.restore_path, name]
    end
    move = move.join(', ')

    sql = "RESTORE DATABASE [%s] FROM DISK = N'%s' WITH FILE = %d, REPLACE, NOUNLOAD, RECOVERY, %s" % \
      [@cmdLine.options.restore_as, @cmdLine.options.file, @file_position, move]
    log(Log::DEBUG, sql)
    @objConnection.CommandTimeout = @cmdLine.options.timeout
    @objConnection.Execute(sql)
    log(Log::WARN, 'DONE')
  end
end # class TRestorer

end # module SQL

# if run directly (not a module)
if __FILE__ == $0
  cmdLine = SQL::RestorerOptions.new(ARGV.dup)
  restorer = SQL::Restorer.new(cmdLine)
  restorer.run
end
