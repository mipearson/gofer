require 'spec_helper'
require 'tempfile'

describe Gofer::Host do

  before :all do
    @host = Gofer::Host.new(test_hostname, test_username, :keys => [test_identity_file], :quiet => true)
    @tmpdir = raw_ssh("mktemp -d /tmp/gofertest.XXXXX").chomp
    make_tmpdir
  end

  after(:all) { clean_tmpdir }

  describe :new do
    before(:each) { Gofer::Host.any_instance.stub(:warn => nil) }
    it "should support the legacy positional argument" do
      Gofer::Host.new(test_hostname, test_username, test_identity_file).run("echo hello", :quiet => true).should == "hello\n"
    end

    it "should support the legacy identity_file key" do
      Gofer::Host.new(test_hostname, test_username, :identity_file => test_identity_file).run("echo hello", :quiet => true).should == "hello\n"
    end
  end

  describe :hostname do
    it "should be the hostname of the host we're connecting to" do
      @host.hostname.should == test_hostname
    end
  end

  shared_examples_for "an output capturer" do
    it "and capture stdout in @response.stdout" do
      @response.stdout.should == "stdout\n"
    end

    it "and capture stderr in @response.stderr" do
      @response.stderr.should == "stderr\n"
    end

    it "and combine captured stdout / stderr in @response.output" do
      @response.output.should == "stdout\nstderr\n"
    end

    it "and @response by itself should be the captured stdout" do
      @response.should == "stdout\n"
    end
  end

  describe :run do

    describe "with a stdout and stderr responses" do
      before :all do
        @response = @host.run "echo stdout; echo stderr 1>&2", :quiet_stderr => true
      end

      it_should_behave_like "an output capturer"
    end


    it "should print stdout responses if quiet is false" do
      $stdout.should_receive(:write).with "stdout\n"
      @host.run "echo stdout", :quiet => false
    end

    it "should print stderr responses if quiet_stderr is false" do
      $stderr.should_receive(:write).with "stderr\n"
      @host.run "echo stderr 1>&2", :quiet_stderr => false
    end

    context "with a host output prefix" do
      before do
        @host.output_prefix = "derp"
        with_captured_output
      end
      it "should prefix each line of the stdout and stderr responses with the output prefix" do
        @host.run "echo stdout; echo stdout2; echo stderr 1>&2; echo stderr2 1>&2", :quiet => false, :quiet_stderr => false
        @stdout.should eq "derp: stdout\nderp: stdout2\n"
        @stderr.should eq "derp: stderr\nderp: stderr2\n"
      end

      it "should not prefix if the output is not actually on a new line" do
        @host.run "echo -n foo; echo bar; echo baz; ", :quiet => false
        @combined.should eq "derp: foobar\nderp: baz\n"
      end

      it "should process stdin when stdin is set" do
        @host.run "sed 's/foo/baz/'", :stdin => "foobar", :quiet => false
        @stdout.should eq "derp: bazbar\n"
      end
    end

    it "should error if a command returns a non-zero response" do
      lambda {@host.run "false"}.should raise_error(/failed with exit status/)
      begin
        @host.run "false"
      rescue Gofer::HostError => e
        e.response.should be_a Gofer::Response
        e.host.should be_a Gofer::Host
      end
    end

    it "should capture a non-zero exit status if asked" do
      response = @host.run "false", :capture_exit_status => true
      response.exit_status.should == 1
    end
  end

  describe :exist? do
    it "should return true if a path or file exists" do
      raw_ssh "touch #{in_tmpdir 'exists'}"
      @host.exist?(in_tmpdir 'exists').should be true
    end

    it "should return false if a path does not exist" do
      @host.exist?(in_tmpdir 'doesnotexist').should be false
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

  describe :write do
    it "should write a file to the remote server" do
      @host.write("some data\n", in_tmpdir('written'))
      raw_ssh("cat #{in_tmpdir 'written'}").should == "some data\n"
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
end
