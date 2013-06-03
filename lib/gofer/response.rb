module Gofer

  # Response container for the various outputs from Gofer::Host#run
  class Response < String

    # Captured STDOUT output
    attr_reader :stdout

    # Captured STDERR output
    attr_reader :stderr

    # Combined STDOUT / STDERR output (also value of this as a String)
    attr_reader :output

    # Exit status of command, only available if :capture_exit_status is used
    attr_reader :exit_status

    def initialize (_stdout, _stderr, _output, _exit_status) # :nodoc:
      super _stdout
      @stdout = _stdout
      @stderr = _stderr
      @output = _output
      @exit_status = _exit_status
    end
  end
end
