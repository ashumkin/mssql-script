#!/usr/bin/env ruby

unless $:.include? File.expand_path('../../lib/', __FILE__)
  $:.unshift File.expand_path('../../lib/', __FILE__)
end

require 'mssql/script/transfer'

cmdLine = MSSQL::Script::TransferOptions.new(ARGV.dup)
scripter = MSSQL::Script::Transfer.new(cmdLine)
scripter.run
