require 'spec_helper'
require 'tempfile'

describe Gofer do
 
  HOSTNAME = ENV['TEST_HOST'] || 'localhost'
  USERNAME = ENV['TEST_USER'] || ENV['USER']
  IDENTITY_FILE = ENV['TEST_IDENTITY_FILE'] || '~/.ssh/id_rsa'

  def raw_ssh command
    out = `ssh -o PasswordAuthentication=no -ni #{IDENTITY_FILE} #{USERNAME}@#{HOSTNAME} #{command}`
    raise "Command #{command} failed" unless $? == 0 
    out
  end

  def in_tmpdir path
    File.join(@tmpdir, path)
  end
    
  def with_local_tmpdir template
    f = Tempfile.new template
    path = f.path
    f.unlink
    FileUtils.mkdir path
    begin
      yield path
    ensure
      FileUtils.rm_rf path unless ENV['KEEPTMPDIR']
    end
  end
    
  before :all do
    @host = Gofer::Host.new(USERNAME, HOSTNAME, IDENTITY_FILE)
    @tmpdir = raw_ssh("mktemp -d /tmp/gofertest.XXXXX").chomp
  end

  after :all do
    if ENV['KEEPTMPDIR']
      puts "TMPDIR is #{@tmpdir}"
    else
      raw_ssh "rm -rf #{@tmpdir}" if @tmpdir && @tmpdir =~ %r{gofertest}
    end
  end

  describe :run do
    it "should run a command and capture its output" do
      output = @host.run "echo hello", :quiet => true
      output.should == "hello\n"
    end

    it "should run a command not capture its stderr by default" do
      output = @host.run "echo hello 1>&2", :quiet_stderr => true
      output.should == ""
    end

    it "should run a command capture its stderr if asked" do
      output = @host.run "echo hello 1>&2", :quiet_stderr => true, :capture_stderr => true
      output.should == "hello\n"
    end
  
    it "should error if a command returns a non-zero response" do
      lambda {@host.run "false"}.should raise_error /failed with exit status/
    end

    it "should capture a non-zero exit status if asked" do
      @host.run "false", :capture_exit_status => true
      @host.last_exit_status.should == 1
    end
  end

  describe :exists? do
    it "should return true if a path or file exists" do
      raw_ssh "touch #{in_tmpdir 'exists'}"
      @host.exists?(in_tmpdir 'exists').should be true
    end

    it "should return false if a path does not exist" do
      @host.exists?(in_tmpdir 'doesnotexist').should be false
    end
  end

  describe :directory? do
    it "should return true if a path is a directory" do
      @host.directory?(@tmpdir).should be true
    end

    it "should return false if a path is not a directory" do
      raw_ssh "touch #{in_tmpdir 'a_file'}"
      @host.directory?(in_tmpdir('a_file')).should be false
    end
  end

  describe :read do
    it "should read in the contents of a file" do
      raw_ssh "echo 'hello' > #{@tmpdir}/hello.txt"
      @host.read(@tmpdir + '/hello.txt').should == "hello\n"
    end
  end
    
  describe :ls do
    it "should list the contents of a directory" do
      raw_ssh "mkdir #{@tmpdir}/lstmp && touch #{@tmpdir}/lstmp/f"
      @host.ls(@tmpdir + '/lstmp').should == ['f']
    end
  end

  describe :upload do
    it "should upload a file to the remote server" do
      f = Tempfile.new('upload_tmp')
      begin
        f.write('uploadtmp')
        f.close
        @host.upload(f.path, in_tmpdir('uploaded'))
        raw_ssh("cat #{in_tmpdir 'uploaded'}").should == 'uploadtmp'
      ensure
        f.unlink
      end
    end
    it "should upload a directory to the remote server" do
      f = with_local_tmpdir('upload_dir_tmp') do |path|
        system "echo 'hey' >> #{File.join(path, 'temp')}"
        @host.upload(path, in_tmpdir('uploaded_dir'))
        raw_ssh("cat #{in_tmpdir 'uploaded_dir/temp'}").should == "hey\n"
      end
    end
  end

  describe :download do
    it "should download a file from the remove server" do
      f = Tempfile.new('download_dir')
      begin
        f.close
        raw_ssh "echo 'download' > #{in_tmpdir 'download'}"
        @host.download(in_tmpdir('download'), f.path)
        File.open(f.path).read.should == "download\n"
      ensure
        f.unlink
      end
    end

    it "should download a directory from the remote server" do
      with_local_tmpdir 'download_dir' do |path|
        download_dir = in_tmpdir 'download_dir'
        raw_ssh "mkdir #{download_dir} && echo 'sup' > #{download_dir}/hey"
      
        @host.download(download_dir, path)
        File.open(path + '/download_dir/hey').read.should == "sup\n"
      end
    end
  end

  describe :within
end
