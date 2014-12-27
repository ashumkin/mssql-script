#!/usr/bin/env ruby

require 'mssql/script/restore'

cmdLine = MSSQL::RestorerOptions.new(ARGV.dup)
restorer = MSSQL::Restorer.new(cmdLine)
restorer.run

