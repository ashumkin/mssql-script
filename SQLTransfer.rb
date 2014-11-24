#!/usr/bin/env ruby
# vim: set shiftwidth=2 tabstop=2 expandtab:
# encoding: Windows-1251

require 'optparse'
require 'ostruct'

#ScriptType
SQLDMOScript_Aliases = 16384
SQLDMOScript_AppendToFile=256
SQLDMOScript_Bindings=128
SQLDMOScript_ClusteredIndexes=8
SQLDMOScript_DatabasePermissions = 32
SQLDMOScript_Default=4
SQLDMOScript_DRI_All=532676608
SQLDMOScript_DRI_AllConstraints=520093696
SQLDMOScript_DRI_AllKeys=469762048
SQLDMOScript_DRI_Checks=16777216
SQLDMOScript_DRI_Clustered=8388608
SQLDMOScript_DRI_Defaults=33554432
SQLDMOScript_DRI_ForeignKeys=134217728
SQLDMOScript_DRI_NonClustered=4194304
SQLDMOScript_DRI_PrimaryKey=268435456
SQLDMOScript_DRI_UniqueKeys=67108864
SQLDMOScript_DRIIndexes=65536
SQLDMOScript_DRIWithNoCheck=536870912
SQLDMOScript_Drops=1
SQLDMOScript_IncludeHeaders=131072
SQLDMOScript_IncludeIfNotExists=4096
SQLDMOScript_Indexes=73736
SQLDMOScript_NoCommandTerm=32768
SQLDMOScript_NoDRI=512
SQLDMOScript_NoIdentity=1073741824
SQLDMOScript_NonClusteredIndexes=8192
SQLDMOScript_ObjectPermissions=2
SQLDMOScript_OwnerQualify=262144
SQLDMOScript_PrimaryObject=4
SQLDMOScript_TimestampToBinary=524288
SQLDMOScript_ToFileOnly=64
SQLDMOScript_Triggers=16
SQLDMOScript_UDDTsToBaseType=1024
SQLDMOScript_UseQuotedIdentifiers=-1
SQLDMOScript_Permissions = SQLDMOScript_DatabasePermissions or SQLDMOScript_ObjectPermissions

#ScriptType2
SQLDMOScript2_70Only=16777216
SQLDMOScript2_AgentAlertJob=2048
SQLDMOScript2_AgentNotify=1024
SQLDMOScript2_AnsiFile=2
SQLDMOScript2_AnsiPadding=1
SQLDMOScript2_Default=0
SQLDMOScript2_EncryptPWD=128
SQLDMOScript2_ExtendedOnly=67108864
SQLDMOScript2_ExtendedProperty=4194304
SQLDMOScript2_FullTextCat=2097152
SQLDMOScript2_FullTextIndex=524288
SQLDMOScript2_JobDisable=33554432
SQLDMOScript2_LoginSID=8192
SQLDMOScript2_NoCollation=8388608
SQLDMOScript2_NoFG=16
SQLDMOScript2_NoWhatIfIndexes=512
SQLDMOScript2_UnicodeFile=4

# !!! ERROR in MSDN !!!
# SQLDMOObj_UserDefinedDatatype & SQLDMOObj_UserDefinedFunction values are reversed
SQLDMOObj_UserDefinedDatatype = 1
SQLDMOObj_UserDefinedFunction = 4096
SQLDMOObj_View = 4
SQLDMOObj_UserTable = 8
SQLDMOObj_StoredProcedure = 16
SQLDMOObj_Trigger = 256
SQLDMOObj_AllDatabaseUserObjects = 4605

SQLDMOXfrFile_SummaryFiles = 1
SQLDMOXfrFile_SingleFilePerObject = 4
SQLDMOXfrFile_SingleSummaryFile = 8
SQLDMOXfrFile_Default = SQLDMOXfrFile_SummaryFiles

SQLDMOScript_TransferDefault = SQLDMOScript_PrimaryObject | SQLDMOScript_Drops \
  | SQLDMOScript_Bindings | SQLDMOScript_ClusteredIndexes | SQLDMOScript_NonClusteredIndexes \
  | SQLDMOScript_Triggers | SQLDMOScript_ToFileOnly | SQLDMOScript_Permissions | SQLDMOScript_IncludeHeaders \
  | SQLDMOScript_Aliases | SQLDMOScript_IncludeIfNotExists | SQLDMOScript_OwnerQualify \
  | SQLDMOScript_DRIWithNoCheck
# -- Begin Main Code Execution --

class File
  unless defined? File.is_cygwin
  def self.is_cygwin?
    RUBY_PLATFORM.downcase.include?("cygwin")
  end
  end

  unless defined? File.expand_path2
  def self.expand_path2(path)
    path = expand_path(path)
    return path if !is_cygwin?
    # конвертируем в путь Windows
    a = `cygpath -w #{path}`.chomp
    return a
  end
  end
end

class FileReader
  def self.ruby18?
    return RUBY_VERSION =~ /^1\.8/
  end

  def self.readlines(file)
    if ruby18?
      return IO.readlines(file)
    else
      # files of scripts are in Windows-1251
      return IO.readlines(file, { :encoding => 'Windows-1251' })
    end
  end
end

# command line options parser class
class TScripterCmdLine < OptionParser
  attr_reader :options, :debug, :verbose, :concat, :run,
    :getVersion, :incVersion, :decVersion

  def initialize(args)
    super()
    @debug = false
    @verbose = true
    @concat = false
    @run = false
    @getVersion = false
    @incVersion =  false
    @decVersion = false
    @level = -1
    @options = OpenStruct.new
    @options.host = \
    @options.db = \
    @options.user = \
    @options.pass = \
    @options.output = \
    @options.list = \
    @options.dep_list = \
    @options.db_version_file = \
    @options.file = ""
    @options.objects = []

    separator ""
    separator "Options:"

    init
    parse!(args)
    validate
  end

  def objects
    @options.objects
  end

  def log(level, msg)
    if level >= @level
      puts msg
    end
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

  def initObjSQL(objSQL)
    objSQL.LoginSecure = @options.user.empty?
    objSQL.Login = @options.user
    objSQL.Password = @options.pass
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
      @options.user = user
    end

    on("-o", "--output DIR",
        "Output directory") do |dir|
      @options.output = dir
    end

    on("-l", "--list FILELIST",
        "File of output list") do |list|
      @options.list = list
    end

    on("-L", "--dep-list DEP_FILELIST",
        "File of output list") do |list|
      @options.dep_list = list
    end

    on("-f", "--file [FILE]",
        "File") do |f|
      @options.file = f
    end

    on("-r", "--run",
        "run scripting (implies -v)") do
      @run = true
      @getVersion = true
    end

    on("-C", "--concatenate [FILE]",
        "Concatenate all objects to one script according to order and dependencies in <DEP_FILELIST>") do |file|
      @concat = true
    end

    on('-F', '--version-file [FILE]',
        'File containing DB version number') do |file|
      @options.db_version_file = file.to_s
    end

    on("-v", '--[no-]get-version',
        "Get DB version into script file") do |v|
      @getVersion = v
    end

    on("-V", "--inc-version [FILE]",
        "Increment and get DB version into script file (implies -v") do |file|
      @getVersion = true
      @incVersion = true
      @decVersion = file == 'minus'
    end

    on("-q", "--quiet",
        "Quiet mode") do
      @verbose = false
    end

    on("-D", "--debug",
        "Debug mode") do
      @debug = true
      @verbose = true
    end

    on("-O", "--objects [<objects-list>]",
        "Objects list") do |objs|
      @options.objects += objs.split(/;|,/)
    end

    # No argument, shows at tail.  This will print an options summary.
    # Try it and see!
    on_tail("-h", "--help", "Show this message") do
      puts help
      exit
    end
  end  # parseargs()

  def validate
    @options.host = 'localhost' if @options.host.empty?
    if @options.db.empty?
      $stderr.puts 'DB is not defined' if @options.db.empty?
      $stderr.puts help
      exit
    end

    @options.user = @options.user.to_s
    a = @options.user.split(":")
    @options.user = a[0].to_s
    @options.pass = a[1].to_s

    @options.output = "DBScripts" if @options.output.empty?
    @options.output = File.expand_path2(@options.output)
    @options.list = @options.output + '/list.txt' if @options.list.empty?

    @options.dep_list = './resources/Script-deps.txt' if @options.dep_list.empty?
    @options.dep_list = File.expand_path2(@options.dep_list)

    @options.file = './resources/Script.txt' if @options.file.empty?
    @options.file = File.expand_path2(@options.file)

    @options.db_version_file = './resources/db-version.inc' if @options.db_version_file.empty?
    @options.db_version_file = File.expand_path(@options.db_version_file)
  end

  def getUser
    return @options.user.empty? ? "trusted" : @options.user
  end
end  # class TScripterCmdLine

class FakeDBObject
  def initialize(name)
    @name = name
  end

  def Name
    @name
  end

  def SystemObject
    false
  end

  def Triggers
    []
  end
end

class TObject
  attr_reader :errors

  def initialize
    @errors = []
  end

  def checkErrors
    if isErrors?
      exit @errors.length
    end
  end

  def addError(name, descr)
    $stderr.puts descr
    if name.is_a?(Array)
      @errors += name
    else
      @errors << name
    end
  end

  def isErrors?
    return !@errors.empty?
  end
end

class TScripter < TObject
  def initialize(cmdLine)
    super()
    @cmdLine = cmdLine
    @objSQL = nil
    @objTransfer = nil
    @objDB = nil
    @objList = TDBObjects.new
  end

  def run
    oldEOL = $\
    # set EOL explicitly
    $\ = (RUBY_PLATFORM !~ /mingw|mswin/ ? "\r" : '') + "\n"
    begin
      if @cmdLine.run
        dorun
        saveList
      end
      getDBVersion if @cmdLine.getVersion
      concatenate if @cmdLine.concat
    ensure
      # restore EOL
      $\ = oldEOL
    end
  end

  def saveList
    # save objects list only if no particular objects were exported
    return if !@cmdLine.objects.empty?
    aFile = File.new(@cmdLine.options.list, "w")
    aFile.write("#!!!DO NOT MODIFY THIS FILE! IT IS GENERATED AUTOMATICALLY!" + $\)
    aFile.write(@objList.list)
    aFile.close
  end

  def concatenate
    dbObjects = TDBObjects.new
    dbObjects.concat(@cmdLine.options.output, @cmdLine.options.file,
      @cmdLine.options.list, @cmdLine.options.dep_list, @cmdLine.verbose)
    dbObjects.checkErrors
    # insert script version
    saveScriptVersion(readDBVersion, @cmdLine)
  end

  def select_version_sql
    raise "Please, redefine #{self.class.to_s}.select_version_sql method"
  end

  def update_version_sql(cmdLine)
    raise "Please, redefine #{self.class.to_s}.update_version_sql method"
  end

  def saveScriptVersion(version, cmdLine)
    raise "Please, redefine #{self.class.to_s}.saveScriptVersion method"
  end

  def getDBVersion
    initCOM
    if @cmdLine.verbose
      puts @cmdLine.indicate
      puts "Getting version..."
    end
    if @cmdLine.debug
      puts @cmdLine.getConnectionStr
    end
    objConnection = WIN32OLE.new("ADODB.Connection")
    objRecordSet = WIN32OLE.new("ADODB.Recordset")
    objConnection.Open(@cmdLine.getConnectionStr)
    # increment/decrement version
    if @cmdLine.incVersion
      objConnection.Execute(update_version_sql(@cmdLine))
    end
    # get version
    objRecordSet.Open(select_version_sql, objConnection)
    version = ""
    if not objRecordSet.Eof
      version = objRecordSet.Fields(0).Value
    end
    if @cmdLine.verbose
      puts version
    end
    saveDBVersion(version)
    return version
  end

private
  def dorun
    initCOM
    if @cmdLine.verbose
      puts "Scripting..."
      puts @cmdLine.indicate
    end
    @cmdLine.initObjSQL(@objSQL)
    init
    connect
    if !@cmdLine.objects.empty?
      @cmdLine.objects.each do |obj|
        name, ext, type = detectTypeByName(obj)
        scriptObject(FakeDBObject.new(name), ext, type, @cmdLine.options.output)
      end
    else
      scriptObjects(@objDB.Tables, 'TAB',
        SQLDMOObj_UserTable, @cmdLine.options.output)
      scriptObjects(@objDB.Views , 'VIW',
        SQLDMOObj_View, @cmdLine.options.output)
      scriptObjects(@objDB.UserDefinedFunctions  , 'UDF',
        SQLDMOObj_UserDefinedFunction, @cmdLine.options.output)
      scriptObjects(@objDB.StoredProcedures, 'PRC',
        SQLDMOObj_StoredProcedure, @cmdLine.options.output)
    end
  end

  def initCOM
    require 'win32ole'
    # setting codepage has a reason on Ruby 1.9.x
    WIN32OLE.codepage = WIN32OLE::CP_ACP unless FileReader.ruby18?
    if !@objSQL
      @objSQL = WIN32OLE.new('SQLDMO.SQLServer')
    end
    if !@objTransfer
      @objTransfer = WIN32OLE.new('SQLDMO.Transfer')
    end
  end

  def detectTypeByName(fullname)
    # take filename and FIRST "extention" after it
    name, ext = fullname.split('.')
    ext.upcase!
    p ['detectTypeByName: ', name, ext] if @cmdLine.debug
    type = case ext
      when 'TAB'
        SQLDMOObj_UserTable
      when 'VIW'
        SQLDMOObj_View
      when 'UDF'
        SQLDMOObj_UserDefinedFunction
      when 'TRG'
        SQLDMOObj_Trigger
      when 'PRC'
        SQLDMOObj_StoredProcedure
      else
        raise 'Undefined object type ' + fullname
    end
    return name, ext, type
  end

  def readDBVersion
    ver = FileReader.readlines(@cmdLine.options.db_version_file)
    raise "Version is absent in the file '%s'" % @cmdLine.options.db_version_file unless ver[0]
    return ver[0].chomp
  end

  def saveDBVersion(version)
    # save db-version.inc
    file = File.new(@cmdLine.options.db_version_file, "w")
    # append EOL to avoid diffs if that file edited with vim
    file.write(version.to_s + $\)
    file.close
  end

  def connect
    @objSQL.Connect @cmdLine.options.host
    @objDB = @objSQL.Databases(@cmdLine.options.db)
    puts 'Connected to %s.%s (ID=%d)' % [@cmdLine.options.host, @objDB.Name, @objDB.ID]
  end

  def init
    scriptParams = SQLDMOScript_TransferDefault \
      & ~SQLDMOScript_IncludeHeaders \
      & ~SQLDMOScript_IncludeIfNotExists \
      & ~SQLDMOScript_Triggers

    script2Params = SQLDMOScript2_ExtendedProperty \
      | SQLDMOScript2_AnsiFile

    @objTransfer.ScriptType = scriptParams
    @objTransfer.Script2Type = script2Params
    if @cmdLine.debug
      puts "ScriptType=#{@objTransfer.ScriptType.to_s}"
      puts "Script2Type=#{@objTransfer.Script2Type.to_s}"
    end

    @objTransfer.IncludeDependencies = false
    @objTransfer.IncludeLogins = false
    @objTransfer.IncludeUsers = false
  end

  def scriptObject(obj, suffix, objType, dir)
    @objTransfer.RemoveAllObjects
    return false if obj.SystemObject
    @objTransfer.AddObjectByName(obj.Name, objType)
    # indicate progress
    if @cmdLine.verbose
      puts obj.Name
    end
    name = "%s.%s.sql" % [obj.Name, suffix]
    @objDB.ScriptTransfer(@objTransfer, SQLDMOXfrFile_SingleSummaryFile,
        dir + '/' + name)
    # script triggers for tables
    if objType == SQLDMOObj_UserTable || objType == SQLDMOObj_View
      scriptObjects(obj.Triggers, 'TRG', SQLDMOObj_Trigger, dir)
    end
    @objList << name
    return true
  end

  def scriptObjects(objs, suffix, objType, dir)
    objs.each do |obj|
      scriptObject(obj, suffix, objType, dir)
    end
  end
end # class TScripter

class TDBObjects < TObject
  def initialize
    super
    @objects = []
    @deps = []
    @primary = []
    @secondary = []
    @end = []
    @ext = []
  end

  def concat(dir, out_file, list_file, dep_file, verbose)
    puts "List files..."
    read(dir, list_file, verbose)
    checkErrors()
    sort(dep_file)
    puts "\nConcatenating #{@objects.size} files..."
    @objects.each do |obj|
      puts obj if verbose
      ['deps', 'primary', 'secondary', 'end', 'ext'].each do |name|
        # reverse drops
        unshift = name == 'deps'
        name = '@' + name
        r = self.instance_variable_get(name)
        r2 = obj.instance_variable_get(name)
        unless r2.empty?
          if unshift
            r.unshift r2
          else
            r << r2
          end
        end
        self.instance_variable_set(name, r)
      end
    end
    save(out_file)
  end

  # returns list of filenames
  def list
    # add empty string to add EOL at EOF
    return (@objects | ['']).join($\)
  end

  def script
    return [@deps, @primary, @secondary, @end, @ext].join($\ + $\)
  end

  def save(file)
    file = File.new(file, "w")
    file.write(script)
    file.close
  end

  # overloaded << operator
  def << (dbObj)
    @objects << dbObj
  end

  private
  # read object files
  def read(dir, list_file, verbose)
    list = FileReader.readlines(list_file)
    # remove all comments
    list.delete_if { |s| /^\s*#/.match(s) }
    # chomp all strings
    list.map! { |s| s.chomp }
    files = Dir.entries(dir)
    # check all listed files existence
    absent = list - files
    if !absent.empty?
      addError(absent, absent.join(",") + " " \
        + (absent.length == 1 ? "is" : "are") + " absent?!")
      return
    end
    # remove unlisted files
    files = files & list
    # expand filenames
    files.map! { |file| dir + "/" + file}
    # get *.sql files only
    files.reject! { |file| !File.file?(file) }
    files.each do |file|
      puts File.basename(file) if verbose
      @objects << TDBObject.new(self, file)
      checkErrors()
    end
  end

  # sorts by dependencies file
  def sort(dep_file)
    deps = TDependencies.new(dep_file)
    @objects.sort! { |a, b| deps.sort(a, b) }
  end
end

class TDBObject
  attr_reader :name, :type, :deps, :primary, :secondary, :end, :ext

  def initialize(parent, file)
    @parent = parent
    @basename = \
    @deps = \
    @primary = \
    @secondary = \
    @end = \
    @ext = ""
    @type = -1
    @file = file
    extract_name
    read
    parse
  end

  def to_s
    return @basename
  end

  private
  def read
    @text = FileReader.readlines(@file).join('')
  end

  def extract_name
    @basename = File.basename(@file)
    n = @basename.split(".")
    @name = n[0].to_s
    @type = TDBObject.getType(n[1].to_s)
  end

  def self.getType(type)
    return nil if type.nil? || type.empty?
    types = ["TAB", "VIW", "UDF", "PRC", "TRG"]
    return types.index(type.upcase) + 1
  end

  def parse
    # delete all SET QUOTED_IDENTIFIER & SET ANSI_NULLS
    @text.gsub!(/^SET\s(QUOTED_IDENTIFIER|ANSI_NULLS)\s.+?GO\s/im, '')
    ms = /(^CREATE\s.+?\r?\nGO\r?\n(\r?\n)?)/im.match(@text)
    if ms
      @deps = ms.pre_match.strip
      @primary = ms.captures[0].strip
      @end = ms.post_match.strip
    else
      @parent.addError(@name, "#{@name} is corrupted?!")
    end
  end
end

class TDependency
  attr_reader :name, :_type
  def initialize(line)
    @name, @_type = line.chomp.split(":")
    @_type = TDBObject.getType(@_type)
  end

  def self.valid?(line)
    # comments and empty lines are not SQL objects
    line.chomp!
    return !(line =~ /^\s*#/ || line.empty?)
  end
end

class TDependencies
  def initialize(file)
    @deps = []
    read(file)
  end

  def sort(a, b)
    # sort TDBObject by type
    r = correctType(a) <=> correctType(b)
    return r if r != 0
    # for the same types sort by dependencies defined in a file
    r = indexOf(a) <=> indexOf(b)
    return r if r != 0
    r = a.name <=> b.name
    return r
  end

  private
  def read(file)
    lines = FileReader.readlines(file)
    # add valid objects to list
    lines.map { |line| @deps << TDependency.new(line) if TDependency.valid?(line) }
  end

  def indexOf(obj)
    i = r = 0
    @deps.each do |dep|
      i += 1
      if 0 == dep.name.casecmp(obj.name)
        r = i
        break
      end
    end
    # 0 - index of objects not to be explicitly sorted
    # 1 and above - index of existing
    # so, in fact index equals index + 2
    return r + 1
  end

  def get(index)
    return @deps[index - 2]
  end

  def correctType(obj)
    # type "correction"
    # for Views used in functions
    r = obj.type
    if 1 < ( i = indexOf(obj) )
      if !(t = get(i)._type).nil?
        # take redefined type if it is
        r = t
      end
    end
    return r
  end
end

# if run directly (not a module)
if __FILE__ == $0
  cmdLine = TScripterCmdLine.new(ARGV.dup)
  Scripter = TScripter.new(cmdLine)
  Scripter.run
end
