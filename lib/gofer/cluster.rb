require 'thread'

module Gofer
  # A collection of Gofer::Host instances that can run commands simultaneously
  class Cluster

    attr_reader :hosts

    attr_accessor :max_concurrency

    def initialize(parties=[], opts={})
      @hosts = []
      @max_concurrency = opts.delete(:max_concurrency)

      parties.each { |i| self << i }
    end

    def concurrency
      max_concurrency.nil? ? hosts.length : [max_concurrency, hosts.length].min
    end

    def <<(other)
      case other
      when Cluster
        other.hosts.each { |host| self << host }
      when Host
        @hosts << other
      end
    end

    %w{run exist? read directory? ls upload read write}.each do |host_method|
      define_method host_method do |*args|
        threaded(host_method, *args)
      end
    end

    private

    # Spawn +concurrency+ worker threads, each of which pops work off the
    # +_in+ queue, and writes values to the +_out+ queue for syncronisation.
    def threaded(meth, *args)
      _in = run_queue
      length = run_queue.length
      _out = Queue.new
      results = {}
      (0...concurrency).map do
        Thread.new do
          loop do
            host = _in.pop(false) rescue Thread.exit

            results[host] = host.send(meth, *args)
            _out << true
          end
        end
      end

      length.times do
        _out.pop
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
