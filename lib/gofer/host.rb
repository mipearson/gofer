module Gofer
  class HostError < Exception
    def initialize host, message
      super "#{host.hostname}: #{message}"
    end
  end
 
  class Host

    attr_reader :hostname

    def initialize username, _hostname, identity_file=nil
      @hostname = _hostname
      @ssh = SshWrapper.new(username, hostname, identity_file)
    end

    def run command, opts={}
      response = @ssh.run command, opts
      if !opts[:capture_exit_status] && response.exit_status != 0
        raise HostError.new(self, "Command #{command} failed with exit status #{@ssh.last_exit_status}")
      end
      response
    end

    def exists? path
      @ssh.run("sh -c '[ -e #{path} ]'").exit_status == 0
    end

    def read path
      @ssh.read_file path
    end

    def directory? path
      @ssh.run("sh -c '[ -d #{path} ]'").exit_status == 0
    end

    def ls path
      response = @ssh.run "ls -1 #{path}", :quiet => true
      if response.exit_status == 0
        response.stdout.strip.split("\n")
      else
        raise HostError.new(self, "Could not list #{path}, exit status #{response.exit_status}")
      end
    end

    def upload from, to
      @ssh.upload from, to, :recursive => File.directory?(from)
    end

    def download from, to
      @ssh.download from, to, :recursive => directory?(from)
    end
  end
end
