#!/usr/bin/env ruby

unless $:.include? File.expand_path('../../lib/', __FILE__)
  $:.unshift File.expand_path('../../lib/', __FILE__)
end

require 'mssql/script/runner'

cmdLine = MSSQL::Script::RunnerOptions.new(ARGV.dup)
scriptRunner = MSSQL::Script::Runner.new(cmdLine)
exit scriptRunner.run

