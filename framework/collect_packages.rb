module PACKMAN
  def self.collect_packages(config_manager)
    package_root = config_manager.get_value('packman', 'package_root')
    # Collect package names.
    package_names = []
    config_manager.get_keys('packman').each do |key|
      if key =~ /^package_.*/
        package_name = key.to_s.gsub(/^package_/, '').capitalize
        next if not PACKMAN.class_defined?(package_name)
        package_names << package_name
      end
    end
    # Download packages to package_root.
    package_names.each do |package_name|
      package = eval "#{package_name}.new"
      # Recursively download dependency packages.
      package.depends.each do |depend|
        depend_package_name = depend.capitalize
        if not package_names.include? depend_package_name
          depend_package = eval "#{depend_package_name}.new"
          download_package(package_root, depend_package, true)
        end
      end
      # Download current package.
      download_package(package_root, package, false)
    end
  end

  def self.download_package(package_root, package, is_depend)
    # Check if there is any patch to download.
    patch_counter = 0
    package.patches.each do |patch|
      url = patch.first
      sha1 = patch.last
      patch_file = "#{package_root}/#{package.class}.patch.#{patch_counter}"
      if File.exist?(patch_file)
        if PACKMAN.sha1_same?(patch_file, sha1)
          report_notice "Patch #{url} is already downloaded."
          next
        end
      end
      report_notice "Download patch #{url}."
      PACKMAN.download(package_root, url, File.basename(patch_file))
    end
    # Download current package.
    package_file = "#{package_root}/#{package.filename}"
    if File.exist?(package_file)
      if PACKMAN.sha1_same?(package_file, package.sha1)
        if is_depend
          report_notice "Dependency package #{Tty.green}#{package.class}#{Tty.reset} is already downloaded."
        else
          report_notice "Package #{Tty.green}#{package.class}#{Tty.reset} is already downloaded."
        end
        return
      end
    end
    report_notice "Download package #{Tty.red}#{package.class}#{Tty.reset}."
    package.download_to(package_root)
  end
end