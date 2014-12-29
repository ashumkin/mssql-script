#!/usr/bin/env ruby

unless $:.include? File.expand_path('../../lib/', __FILE__)
  $:.unshift File.expand_path('../../lib/', __FILE__)
end

require 'mssql/script/restore'

cmdLine = MSSQL::RestorerOptions.new(ARGV.dup)
restorer = MSSQL::Restorer.new(cmdLine)
restorer.run

