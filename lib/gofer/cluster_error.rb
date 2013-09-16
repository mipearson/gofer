module Gofer
  # Error(s) encountered performing a Gofer command on a cluster of hosts
  class ClusterError < Exception

    # Exception instances by host
    attr_reader :errors

    def initialize errors={}
      @errors = errors
      super errors.values.map(&:to_s).join(', ')
    end
  end
end
