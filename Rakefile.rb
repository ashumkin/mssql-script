# encoding: utf-8
# vim: set shiftwidth=2 tabstop=2 expandtab:
=begin rdoc

=end

require 'rake'
require 'rake/testtask'

desc 'Default are tests'
task :default => :tests

desc 'Тесты'
Rake::TestTask.new('tests') do |t|
  t.verbose = true
end
