module Gofer
  class HostError < Exception
    def initialize host, message
      super "#{host.hostname}: #{message}"
    end
  end
 
  class Host

    attr_reader :last_exit_status, :hostname

    def initialize username, _hostname, identity_file=nil
      @hostname = hostname
      @ssh = SshWrapper.new(username, hostname, identity_file)
    end

    def run command, opts={}
      @ssh.run command, opts
      if opts[:capture_exit_status]
        @last_exit_status = @ssh.last_exit_status
      elsif @ssh.last_exit_status != 0
        raise HostError.new(self, "Command #{command} failed with exit status #{@ssh.last_exit_status}")
      end
      @ssh.last_output
    end

    def exists? path
      @ssh.run "[ -x #{path} ]"
      @ssh.last_exit_status == 0
    end

    def read path
      @ssh.run "cat #{path}", :capture_stderr => false
      if @ssh.last_exit_status == 0
        @ssh.output
      else
        raise HostError.new(self, "Could not read #{path}, exit status #{@ssh.last_exit_status}")
      end
    end

    def ls path
      @ssh.run "ls -1 --color=never #{path}"
      if @ssh.last_exit_status == 0
        @ssh.output.strip.split("\n")
      else
        raise HostError.new(self, "Could not list #{path}, exit status #{@ssh.last_exit_status}")
      end
    end

    def upload from, to
      @ssh.scp_to_host from, to
    end

    def download from, to
      @ssh.scp_from_host from, to
    end

    def within &block
      instance_eval &block
    end
  end
end
