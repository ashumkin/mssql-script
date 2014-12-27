require 'mssql/script/transfer'

cmdLine = MSSQL::Script::TransferOptions.new(ARGV.dup)
scripter = MSSQL::Script::Transfer.new(cmdLine)
scripter.run
