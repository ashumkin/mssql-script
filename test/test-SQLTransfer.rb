#!/usr/bin/env ruby
# vim: set shiftwidth=2 tabstop=2 expandtab:
# encoding: utf-8

require 'test/unit'
require 'stringio'
require 'mssql/script/transfer'
require 'rake'
require 'unixdiff'

# Ruby 1.9 uses "minitest". There is no `name` property there
module Test
  module Unit
    class TestCase
      def name
        __name__
      # Ruby 1.8. returns strings not symbols
      end unless TestCase.instance_methods.include?(:name) || TestCase.instance_methods.include?('name')
    end
  end
end

module MSSQL
  module Script

    class Transfer
      # redefine saveScriptVersion method
      def saveScriptVersion(version, cmdLine)
        # read Scripts.txt
        prevfile = MSSQL::FileReader.readlines(cmdLine.options.file)
        version = version.to_s << $\
        prevfile.insert(0, '--Version=%s%s' % [version, $\])
        # resave Scripts.txt
        File.open(cmdLine.options.file, 'w') do |f|
          f.write(prevfile.join(''))
        end
      end
    end

    class TestTransfer < Test::Unit::TestCase
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

    public
      def setup
        @output = File.expand_path('../resources/output/script.sql', __FILE__)
        args = ['--file', @output]
        # here --output used as far as Transfer is intended to use export DB DDLs to a folder
        # so the same parameter is used for gathering files from that folder
        args << '--output' << File.expand_path('../resources/source/', __FILE__)
        args << '--list' << File.expand_path('../resources/source/list.txt', __FILE__)
        args << '--dep-list' << File.expand_path('../resources/source/dep-list.txt', __FILE__)
        args << '--version-file' << File.expand_path('../resources/source/version.inc', __FILE__)
        args << '--concatenate'
        @opts = TransferOptions.new(args)
        @sqlTransfer = Transfer.new(@opts)
      end

      def test_concatenate
        @sqlTransfer.run
        f_expected = File.expand_path('../resources/expected/all/script.sql', __FILE__)
        test_text_output = FileReader.readlines(@output)
        test_text_expected = FileReader.readlines(f_expected)
        assert_equal_text(test_text_expected, test_text_output, 'script.sql')
      end
    end

  end # module Script
end # module MSSQL

