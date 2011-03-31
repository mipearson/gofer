describe 'Gofer' do
 
  HOSTNAME = ENV['TEST_HOST'] || 'localhost'
  USERNAME = ENV['TEST_USER'] || ENV['USER']
  IDENTITY_FILE = ENV['TEST_IDENTITY_FILE'] || '~/.ssh/id_rsa.pub'

  def check_ssh_ability
    system "ssh -o PasswordAuthentication=no -ni #{IDENTITY_FILE} #{USERNAME}@#{HOSTNAME} true"
    if $? != 0
      $stderr.puts "Can't test without a machine we can ssh to!"
      exit 1
    end
  end
    
  before :all do
    check_ssh_ability
    @host = Gofer::Host.new(HOSTNAME, USERNAME, IDENTITY_FILE)
  end

  describe :run do
    it "should run a command and capture its output" do
      output = @host.run "echo hello"
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
      @host.exists?('/').should be true
    end

    it "should return false if a path does not exist" do
      @host.exists?('/thispathprobablydoesnotexist').should be false
    end
  end

  describe :read
  describe :ls
  describe :upload
  describe :download
  describe :within
end
