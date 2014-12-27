class File
  unless defined? File.is_cygwin
  def self.is_cygwin?
    RUBY_PLATFORM.downcase.include?("cygwin")
  end
  end

  unless defined? File.expand_path2
  def self.expand_path2(path)
    path = expand_path(path)
    return path if !is_cygwin?
    # convert to Windows path
    a = `cygpath -w #{path}`.chomp
    return a
  end
  end
end


