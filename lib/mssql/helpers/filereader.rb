module MSSQL

class FileReader
  def self.ruby18?
    return RUBY_VERSION =~ /^1\.8/
  end

  def self.file_encoding
    'Windows-1251'
  end

  def self.readlines(file)
    if ruby18?
      return IO.readlines(file)
    else
      # files of scripts are in Windows-1251
      return IO.readlines(file, { :encoding => file_encoding })
    end
  end
end

end # module MSSQL
