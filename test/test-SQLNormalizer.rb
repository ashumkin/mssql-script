#!/usr/bin/env ruby
# vim: set shiftwidth=2 tabstop=2 expandtab:
# encoding: utf-8

require 'test/unit'
require 'stringio'
require 'mssql/script/normalizer'
require 'rake'
require 'unixdiff'

# Ruby 1.9 uses "minitest". There is no `name` property there
if defined? MiniTest::Unit::TestCase && Test::Unit::TestCase < MiniTest::Unit::TestCase
  module Test
    module Unit
      class TestCase
        def name
          __name__
        end
      end
    end
  end
end

module MSSQL
  module Script

    class TestNormalizer < Test::Unit::TestCase
    private
      def assert_equal_text(expected, actual, file)
        diff = expected.diff(actual)
        oldoutput = $>
        begin
          $> = diff_text = StringIO.new('')
          diff.to_diff
        ensure
          $> = oldoutput
        end
        assert_equal(true, diff.diffs.empty?, file + ': ' + diff_text.string)
      end

      def _test_files(mask)
        @sqlNormalizer.run
        c = 0
        FileList[File.expand_path('../resources/source/' + mask, __FILE__)].each do |f|
          c += 1
          f_name = File.basename(f)
          f = File.expand_path(f_name, @opts.options.output)
          f_expected = File.expand_path(f_name, File.expand_path('../resources/expected/', __FILE__))
          assert_equal(File.size(f_expected), File.size(f), 'At least file sizes must be equal!')
          test_text_output = FileReader.readlines(f).map!{ |line| line.chomp }
          test_text_expected = FileReader.readlines(f_expected).map!{ |line| line.chomp }
          assert_equal_text(test_text_expected, test_text_output, f_name)
        end
        assert_not_equal(0, c, 'Source files count = 0')
      end

    public
      def setup
        args = ['--file', File.expand_path('../resources/source/', __FILE__)]
        args << '--go'
        args << '--trailing-spaces' if /tables/.match(name)
        args << '--mask' << '*.PRC.sql' if /procedures/.match(name)
        args << '--output' << File.expand_path('../resources/output/', __FILE__)
        @opts = NormalizerOptions.new(args)
        @sqlNormalizer = Normalizer.new(@opts)
      end

      def test_tables
        _test_files('*.TAB.sql')
      end

      def test_procedures
        _test_files('*.PRC.sql')
      end
    end

  end # module Script
end # module MSSQL

