#!/usr/bin/env ruby

require 'mssql/script/runner'

cmdLine = MSSQL::Script::RunnerOptions.new(ARGV.dup)
scriptRunner = MSSQL::Script::Runner.new(cmdLine)
exit scriptRunner.run

