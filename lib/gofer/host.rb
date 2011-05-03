module Gofer
  class HostError < Exception # :nodoc:
    def initialize host, message
      super "#{host.hostname}: #{message}"
    end
  end
 
  class Host
    
    attr_reader :hostname

    # Create a new Host connection
    # 
    # +opts+ is passed through directly to Net::SSH.start
    # See http://net-ssh.github.com/ssh/v2/api/index.html for valid arguments.
    def initialize _hostname, username, opts={}
      @hostname = _hostname
      
      # support legacy positional argument use
      if opts.is_a? String
        opts = { :keys => [opts]}
      end
      
      # support legacy identity_file argument
      if opts[:identity_file]
        opts[:keys] = [opts.delete(:identity_file)]
      end
      
      @ssh = SshWrapper.new(hostname, username, opts)
    end

    # Run +command+.
    #
    # Raise an error if +command+ exits with a non-zero status.
    #
    # Print +stdout+ and +stderr+ as they're received. 
    #
    # Return a Gofer::Response object.
    # 
    # Options:
    #
    # +quiet+:: Don't print +stdout+
    # +quiet_stderr+:: Don't print +stderr+
    # +capture_exit_status+:: Don't raise an error on a non-zero exit status
    def run command, opts={}
      response = @ssh.run command, opts
      if !opts[:capture_exit_status] && response.exit_status != 0
        raise HostError.new(self, "Command #{command} failed with exit status #{@ssh.last_exit_status}")
      end
      response
    end

    # Return +true+ if +path+ exits.
    def exists? path
      @ssh.run("sh -c '[ -e #{path} ]'").exit_status == 0
    end

    # Return the contents of the file at +path+. 
    def read path
      @ssh.read_file path
    end

    # Return +true+ if +path+ is a directory.
    def directory? path
      @ssh.run("sh -c '[ -d #{path} ]'").exit_status == 0
    end

    # Return a list of files in the directory at +path+.
    def ls path
      response = @ssh.run "ls -1 #{path}", :quiet => true
      if response.exit_status == 0
        response.stdout.strip.split("\n")
      else
        raise HostError.new(self, "Could not list #{path}, exit status #{response.exit_status}")
      end
    end

    # Upload the file or directory at +from+ to +to+. 
    def upload from, to
      @ssh.upload from, to, :recursive => File.directory?(from)
    end

    # Download the file or directory at +from+ to +to+
    def download from, to
      @ssh.download from, to, :recursive => directory?(from)
    end
  end
end
