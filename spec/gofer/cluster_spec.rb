require 'spec_helper'

describe Gofer::Cluster do

  before :all do
    @cluster = Gofer::Cluster.new
    # Cheat and use the same host repeatedly
    @host1 = Gofer::Host.new(test_hostname, test_username, :keys => [test_identity_file], :quiet => true)
    @host2 = Gofer::Host.new(test_hostname, test_username, :keys => [test_identity_file], :quiet => true)
    @cluster << @host1
    @cluster << @host2
  end

  it "should run commands in parallel" do
    results = @cluster.run("ruby -e 'puts Time.now.to_f; sleep 0.1; puts Time.now.to_f'")

    res1 = results[@host1].stdout.lines.to_a
    res2 = results[@host2].stdout.lines.to_a

    expect(res1[1].to_f).to be > res2[0].to_f
  end

  it "should respect max_concurrency" do
    @cluster.max_concurrency = 1
    results = @cluster.run("ruby -e 'puts Time.now.to_f; sleep 0.1; puts Time.now.to_f'")

    res1 = results[@host1].stdout.lines.to_a
    res2 = results[@host2].stdout.lines.to_a

    expect(res2[0].to_f).to be >= res1[1].to_f
  end
end

