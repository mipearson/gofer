require 'thread'

module Gofer
  # A collection of Gofer::Host instances that can run commands simultaneously
  #
  # Gofer::Cluster supports most of the methods of Gofer::Host. Commands
  # will be run simultaneously, with up to +max_concurrency+ commands running
  # at the same time. If +max_concurrency+ is unset all hosts in the cluster
  # will receive commands at the same time.
  #
  # Results from commands run are returned in a Hash, keyed by host.
  class Cluster

    # Hosts in this cluster
    attr_reader :hosts

    # Maximum number of commands to run simultaneously
    attr_accessor :max_concurrency

    # Create a new cluster of Gofer::Host connections.
    #
    # +parties+:: Gofer::Host or other Gofer::Cluster instances
    #
    # Options:
    #
    # +max_concurrency+:: Maximum number of commands to run simultaneously
    def initialize(parties=[], opts={})
      @hosts = []
      @max_concurrency = opts.delete(:max_concurrency)

      parties.each { |i| self << i }
    end

    # Currency effective concurrency, either +max_concurrency+ or the number of
    # Gofer::Host instances we contain.
    def concurrency
      max_concurrency.nil? ? hosts.length : [max_concurrency, hosts.length].min
    end

    # Add a Gofer::Host or the hosts belonging to a Gofer::Cluster to this instance.
    def <<(other)
      case other
      when Cluster
        other.hosts.each { |host| self << host }
      when Host
        @hosts << other
      end
    end

    # Run a command on this Gofer::Cluster. See Gofer::Host#run
    def run *args
      threaded(:run, *args)
    end

    # Check if a path exists on each host in the cluster. See Gofer::Host#exist?
    def exist? *args
      threaded(:exist?, *args)
    end

    # Check if a path is a directory on each host in the cluster. See Gofer::Host#directory?
    def directory? *args
      threaded(:directory?, *args)
    end

    # List a directory on each host in the cluster. See Gofer::Host#ls
    def ls *args
      threaded(:ls, *args)
    end

    # Upload to each host in the cluster. See Gofer::Host#ls
    def upload *args
      threaded(:upload, *args)
    end

    # Read a file on each host in the cluster. See Gofer::Host#read
    def read *args
      threaded(:read, *args)
    end

    # Write a file to each host in the cluster. See Gofer::Host#write
    def write *args
      threaded(:write, *args)
    end

    private

    # Spawn +concurrency+ worker threads, each of which pops work off the
    # +_in+ queue, and writes values to the +_out+ queue for syncronisation.
    def threaded(meth, *args, &blk)
      _in = run_queue
      length = _in.length
      _out = Queue.new
      results = {}
      exceptions = []
      concurrency.times do
        Thread.new do
          loop do
            begin
              host = _in.pop(false) rescue Thread.exit

              results[host] = host.send(meth, *args)
              _out << true
            rescue Exception => e
              exceptions << e
              _out << false
            end
          end
        end
      end

      length.times do
        _out.pop
      end

      if blk && !exceptions.empty?
        exceptions.each(&blk)
      end

      results
    end

    def run_queue
      Queue.new.tap do |q|
        @hosts.each do |h|
          q << h
        end
      end
    end
  end
end
