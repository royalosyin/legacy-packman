require "fileutils"

module PACKMAN
  def self.mkexe file
    FileUtils.chmod 0755, file
  end

  def self.cp src, dest
    Dir.glob(src).each do |file|
      FileUtils.cp_r file, dest
    end
  end

  def self.mv src, dest
    Dir.glob(src).each do |file|
      FileUtils.mv file, dest
    end
  end

  def self.rm file_path
    FileUtils.rm_rf Dir.glob(file_path), :secure => true
  end

  def self.ln src, dest, *options
    rm dest if options.include? :remove_link_if_exist and File.symlink? dest
    Dir.glob(src).each do |file|
      FileUtils.ln_sf file, dest
    end
  end

  def self.mkdir dir, *options
    if Dir.exist? dir
      if options.include? :force
        FileUtils.rm_rf dir
      elsif options.include? :skip_if_exist
        return
      elsif not options.include? :silent
        CLI.report_error "Directory #{CLI.red dir} already exists!"
      end
    end
    begin
      FileUtils.mkdir_p(dir)
      CLI.report_notice "Create directory #{CLI.blue dir}." if not options.include? :silent
    rescue => e
      CLI.report_error "Failed to create directory #{CLI.red dir}!\n"+
        "#{CLI.red '==>'} #{e}"
    end
    if block_given?
      FileUtils.chdir(dir)
      yield
    end
  end

  def self.is_directory_empty? dir_path
    Dir.glob("#{dir_path}/*").empty?
  end

  def self.create_parent_directories file_path
    Pathname.new(file_path).dirname.descend do |dir|
      if not Dir.exist? dir
        mkdir dir
      end
    end
  end

  def self.write_file file_path, content
    PACKMAN.report_notice "Write file #{CLI.blue file_path}."
    create_parent_directories file_path
    File.open(file_path, 'w') { |file| file << content }
  end

  def self.append file_path, lines
    create_parent_directories file_path
    FileUtils.touch(file_path) if not File.exist? file_path
    File.open(file_path, 'a') { |file| file << lines }
  end

  def self.contain? file_path, lines
    return false if not File.exist? file_path
    File.open(file_path, 'r').read.include? lines
  end

  def self.replace file_path, replaces, *options
    content = File.open(file_path, 'r').read
    replaces.each do |pattern, replacement|
      if content.gsub!(pattern, replacement) == nil
        if options.include? :silent
          exit
        else
          CLI.report_error "Pattern \"#{pattern}\" is not found in \"#{file_path}\"!" if not options.include? :not_exit
        end
      end
    end
    file = File.open file_path, 'w'
    file << content
    file.close
  end

  def self.delete_from_file file_path, *options
    patterns = options.select { |x| x.class != Symbol }
    if not File.exist? file_path
      return if options.include? :no_error
      PACKMAN.report_error "File #{PACKMAN.red file_path} does not exist!"
    end
    content = File.open(file_path, 'r').read
    patterns.each do |pattern|
      if content.gsub!(pattern, '') == nil and not options.include? :no_error
        CLI.report_error "Pattern \"#{pattern}\" is not found in \"#{file_path}\"!"
      end
    end
    file = File.open file_path, 'w'
    file << content
    file.close
  end

  def self.compression_type file_path, *options
    if file_path =~ /\.tar.Z$/i
      return :tar_Z
    elsif file_path =~ /\.(tar(\..*)?|tgz|tbz2)$/i
      return :tar
    elsif file_path =~ /\.(gz)$/i
      return :gzip
    elsif file_path =~ /\.(bz2)$/i
      return :bzip2
    elsif file_path =~ /\.(zip)$/i
      return :zip
    else
      if not options.include? :not_exit
        CLI.report_error "Unknown compression type of \"#{file_path}\"!"
      else
        return nil
      end
    end
  end

  def self.decompress file_path, *options
    options_from_package = options.select { |x| x.class == Hash }.first || {}
    args = ''
    CLI.report_notice "Decompress #{CLI.blue File.basename(file_path)}." if not options.include? :silent
    if options_from_package.has_key? :put_into_directory
      work_dir = options_from_package[:put_into_directory]
      PACKMAN.mkdir work_dir, :force
    else
      work_dir = '.'
    end
    PACKMAN.work_in work_dir do
      case PACKMAN.compression_type file_path
      when :tar_Z
        if options_from_package.has_key? :strip_top_directories
          args << "--strip-components=#{options_from_package[:strip_top_directories]+1}"
        end
        system "tar xzf #{file_path} #{args}"
      when :tar
        if options_from_package.has_key? :strip_top_directories
          args << "--strip-components=#{options_from_package[:strip_top_directories]+1}"
        end
        system "tar xf #{file_path} #{args}"
      when :gzip
        system "gzip -d #{file_path}"
      when :bzip2
        system "bzip2 -d #{file_path}"
      when :zip
        system "unzip -o #{file_path} 1> /dev/null"
      end
    end
  end

  def self.compress src_path, dst_path, *options
    CLI.report_notice "Compress #{CLI.blue src_path} into #{dst_path}." if not options.include? :silent
    system "tar czf #{dst_path} #{src_path}"
    CLI.report_error 'Failed to compress!' if not $?.success?
  end

  def self.sha1_same? file_path, expect
    if File.file? file_path
      expect.eql? Digest::SHA1.hexdigest(File.read(file_path))
    elsif File.directory? file_path
      tmp = []
      Dir.glob("#{file_path}/**/*").each do |file|
        next if File.directory? file
        tmp << Digest::SHA1.hexdigest(File.read(file))
      end
      current = Digest::SHA1.hexdigest(tmp.sort.join)
      if expect.eql? current
        return true
      else
        CLI.report_warning "Directory #{file_path} SHA1 is #{current}."
        return false
      end
    else
      CLI.report_error "Unknown file type \"#{file_path}\"!"
    end
  end
end
