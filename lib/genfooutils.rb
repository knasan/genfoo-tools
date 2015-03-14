class GenfooUtils

  def set_logfile
    # set default log, for user /tmp - for root /var/log
    if Process.uid == 0
      @logfile = "/var/log/#{File.basename($0)}.log"
    else
      @logfile = "/tmp/#{File.basename($0)}.log"
    end
  end

  #set logfile for more output informations
  def initialize_logger(_options)
    if _options[:logfile]
      log = Logger.new(_options[:logfile])
    else
      log = Logger.new(@logfile)
    end
    log
  end

  def output_as(_arg, _options, _op)
    if _arg == 'file' or _arg == 'f'
      _options[:output_as] = 'file'
    elsif _arg == 'dir' or _arg == 'f' or _arg == 'd'
      _options[:output_as] = 'dir'
    else
      puts 'output_as file [f | file] or as directory [d | dir]'
      puts _op
      exit
    end
    _options
  end

  def check_file_or_directory(_file, _options, _log)
    if File.exist?(_file)
      pkgscan(_options)
    else
      error_msg = "failure: #{_file} no file or directory"
      _log.error(error_msg)
      puts error_msg
      puts op
      exit
    end
  end

  def show_comment(_line, _comment_tmp_file)
    if _line.start_with?('#')
      comment = _line.split(/#/)[1]
      comment = comment.strip unless comment.nil?
      _comment_tmp_file.puts(comment)
    else
      comment = _line.split(/#/)[1]
      comment = comment.strip unless comment.nil?
    end
    comment
  end

  def migrate_to_dir(_file)
    begin
      # create a tmp dir, is exists delete it
      tmpdir = Dir.mktmpdir(File.basename($0))
      mydir  = File.join(tmpdir, _file)
      FileUtils.mkdir(mydir)

      File.readlines(TMPFILE).each do |line|
        info, _ = line.split(/ /)
        info    = info.strip
        catname = info.split(/=/)[1].to_s.split(/\//)[0]
        catname = info.split(/\//)[0] if catname.nil?

        File.new("#{mydir}/#{catname}", 'a').syswrite(line)
      end

      file_tmp_path = File.join('/tmp', _file)
      FileUtils.rm_rf(file_tmp_path)

      FileUtils.cp_r(mydir, file_tmp_path)

      FileUtils.rm_r(tmpdir)
    rescue
      return false
    end
    true
  end

  def save_as_file_and_exit(_options, _file, _log)
    unless _options[:output_as] == 'dir'
      newfile = File.join('/tmp/', _file)
      FileUtils.cp(TMPFILE, newfile)
      info_msg = "new packages.use is saved as File to: #{newfile}"
      _log.info("#{info_msg}")
      puts info_msg
      exit
    end
  end

  def save_as_directory_and_exit(_options, _directory, _log)
    if _options[:output_as] == 'dir'
      result = migrate_to_dir(_directory)
      unless result
        error_msg = "unkown error, #{_directory} not saved"
        _log.error("#{error_msg}")
        puts error_msg
        exit
      end
      info_msg = "new #{_directory} is saved as directory to: /tmp/#{_directory}"
      _log.info("#{info_msg}")
      puts info_msg
      exit
    end
  end

end
