require 'spec_helper'

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

  describe :upload
  describe :download
  describe :within
end
