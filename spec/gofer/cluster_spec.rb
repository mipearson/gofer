require 'spec_helper'

describe Gofer::Cluster do

  before :all do
    @cluster = Gofer::Cluster.new
    # Cheat and use the same host repeatedly
    @host1 = Gofer::Host.new(test_hostname, test_username, :keys => [test_identity_file], :quiet => true)
    @host2 = Gofer::Host.new(test_hostname, test_username, :keys => [test_identity_file], :quiet => true)
    @cluster << @host1
    @cluster << @host2
    make_tmpdir
  end

  after(:all) { clean_tmpdir }

  it "should run commands in parallel" do
    results = @cluster.run("bash -l -c \"ruby -e 'puts Time.now.to_f; sleep 0.1; puts Time.now.to_f'\"")

    res1 = results[@host1].stdout.lines.to_a
    res2 = results[@host2].stdout.lines.to_a

    expect(res1[1].to_f).to be > res2[0].to_f
  end

  it "should respect max_concurrency" do
    @cluster.max_concurrency = 1
    results = @cluster.run("bash -l -c \"ruby -e 'puts Time.now.to_f; sleep 0.1; puts Time.now.to_f'\"")

    res1 = results[@host1].stdout.lines.to_a
    res2 = results[@host2].stdout.lines.to_a

    expect(res2[0].to_f).to be >= res1[1].to_f
  end

  it "should encapsulate errors in a Gofer::ClusterError container exception" do
    expect { @cluster.run("false") }.to raise_error(Gofer::ClusterError)
    begin
      @cluster.run "false"
    rescue Gofer::ClusterError => e
      expect(e.errors.keys.length).to eq(2)
      expect(e.errors[@host1]).to be_a(Gofer::HostError)
      expect(e.errors[@host2]).to be_a(Gofer::HostError)
    end
  end

  # TODO: Make this a custom matcher?
  def results_should_eq expected, &block
    results = block.call
    results[@host1].should eq expected
    results[@host2].should eq expected
  end

  describe :exist? do
    it "should return true if a directory exists" do
      results_should_eq(true) { @cluster.exist?(@tmpdir) }
      results_should_eq(false) { @cluster.exist?(@tmpdir + '/blargh') }
    end
  end

  describe :directory? do
    it "should return true if a path is a directory" do
      results_should_eq(true) { @cluster.directory?(@tmpdir)}
      raw_ssh "touch #{@tmpdir}/a_file"
      results_should_eq(false) { @cluster.directory?("#{@tmpdir}/a_file")}
    end
  end

  describe :read do
    it "should read in the contents of a file" do
      raw_ssh "echo hello > #{@tmpdir}/hello.txt"
      results_should_eq("hello\n") { @cluster.read(@tmpdir + '/hello.txt')}
    end
  end

  describe :ls do
    it "should list the contents of a directory" do
      raw_ssh "mkdir #{@tmpdir}/lstmp && touch #{@tmpdir}/lstmp/f"
      results_should_eq(['f']) { @cluster.ls(@tmpdir + '/lstmp') }
    end
  end

  describe :upload do
    it "should upload a file to the remote server" do
      pending "testing problematic as we're connecting to the same host twice"
    end
  end

  describe :write do
    it "should write a file to the remote server" do
      pending "testing problematic as we're connecting to the same host twice"
    end
  end

  describe :download do
    it "should deliberately not be implemented as destination files would be overwritten" do
      expect { @cluster.download("whut") }.to raise_error(NoMethodError)
    end
  end
end
