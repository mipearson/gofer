require 'thread'

module Gofer
  class Cluster
    attr_reader :hosts
    attr_accessor :max_concurrency
    def initialize(parties=[])
      @hosts = []
      @max_concurrency = nil

      parties.each do |i|
        self << i
      end
    end

    def <<(other)
      case other
      when Cluster
        other.hosts.each do |host|
          @hosts << host
        end
      when Host
        @hosts << other
      end
    end

    def run(opts={}, &block)
      concurrency = opts[:max_concurrency] || max_concurrency || hosts.length
      block.call(ClusterCommandRunner.new(hosts, concurrency))
    end

    class ClusterCommandRunner
      def initialize(hosts, concurrency)
        @concurrency = concurrency
        @hosts = hosts
      end

      # Spawn +concurrency+ worker threads, each of which pops work off the
      # +_in+ queue, and writes values to the +_out+ queue for syncronisation.
      def run(cmd, opts={})
        _in = run_queue
        length = run_queue.length
        _out = Queue.new
        results = {}
        (0...@concurrency).map do
          Thread.new do
            loop do
              host = _in.pop(false) rescue Thread.exit

              results[host] = host.run(cmd, opts)
              _out << true
            end
          end
        end

        length.times do
          _out.pop
        end

        return results
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
end
