module Gofer
  # An error encountered performing a Gofer command
  class HostError < Exception

    # Instance of Gofer::Host that raised the error
    attr_reader :host

    # Instance of Gofer::Response encapsulating the error output
    attr_reader :response

    def initialize host, response, message
      @host = host
      @response = response
      super "#{host.hostname}: #{message}"
    end
  end
end
