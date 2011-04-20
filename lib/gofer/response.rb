module Gofer
  class Response < String
    attr_reader :stdout, :stderr, :output, :exit_status
    
    def initialize (_stdout, _stderr, _output, _exit_status)
      super _stdout
      @stdout = _stdout
      @stderr = _stderr
      @output = _output
      @exit_status = _exit_status
    end
  end
end