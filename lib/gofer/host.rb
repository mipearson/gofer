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
      @ssh.run "sh -c '[ -e #{path} ]'"
      @ssh.last_exit_status == 0
    end

    def read path
      @ssh.read_file path
    end

    def directory? path
      @ssh.run "sh -c '[ -d #{path} ]'"
      @ssh.last_exit_status == 0
    end

    def ls path
      @ssh.run "ls -1 --color=never #{path}", :quiet => true
      if @ssh.last_exit_status == 0
        @ssh.last_output.strip.split("\n")
      else
        raise HostError.new(self, "Could not list #{path}, exit status #{@ssh.last_exit_status}")
      end
    end

    def upload from, to
      @ssh.upload from, to, :recursive => File.directory?(from)
    end

    def download from, to
      @ssh.download from, to, :recursive => directory?(from)
    end

    def within &block
      instance_eval &block
    end
  end
end
