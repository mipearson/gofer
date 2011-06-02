require 'tempfile'

module Gofer
  class HostError < Exception # :nodoc:
    def initialize host, message
      super "#{host.hostname}: #{message}"
    end
  end
 
  class Host
    
    attr_reader :hostname
    attr_accessor :quiet

    # Create a new Host connection
    # 
    # Options:
    # 
    # +quiet+:: Don't print stdout output from +run+ commands
    # All other+opts+ is passed through directly to Net::SSH.start
    # See http://net-ssh.github.com/ssh/v2/api/index.html for valid arguments.
    def initialize _hostname, username, opts={}
      @hostname = _hostname
      
      # support legacy positional argument use
      if opts.is_a? String
        opts = { :keys => [opts]}
      end
      
      @quiet = opts.delete(:quiet)
      
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
    # +quiet+:: Don't print +stdout+, can also be set with +quiet=+ on the instance
    # +quiet_stderr+:: Don't print +stderr+
    # +capture_exit_status+:: Don't raise an error on a non-zero exit status
    def run command, opts={}
      opts[:quiet] = quiet unless opts.include?(:quiet)
      response = @ssh.run command, opts
      if !opts[:capture_exit_status] && response.exit_status != 0
        raise HostError.new(self, "Command #{command} failed with exit status #{@ssh.last_exit_status}")
      end
      response
    end
    
    # Run +commands+ one by one in order.
    #
    # Raise an error if a command in +commands+ exits with a non-zero status.
    #
    # Print +stdout+ and +stderr+ as they're received. 
    #
    # Return a Gofer::Response object.
    # 
    # Options:
    #
    # +quiet+:: Don't print +stdout+, can also be set with +quiet=+ on the instance
    # +quiet_stderr+:: Don't print +stderr+
    #
    # The behaviour of passing +capture_exit_status+ here is undefined.
    def run_multiple commands, opts={}
      return if commands.empty?
      
      responses = commands.map do |command|
        run command, opts
      end
      
      first_response = responses.shift
      responses.reduce(first_response) do |cursor, response|
        Response.new(cursor.stdout + response.stdout, cursor.stderr + response.stderr, cursor.output + response.output, 0)
      end
    end

    # Return +true+ if +path+ exits.
    def exist? path
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
    
    # Write +data+ to a file at +to+
    def write data, to
      Tempfile.open "gofer_write" do |file|
        file.write data
        file.close
        @ssh.upload(file.path, to, :recursive => false)
      end
    end
  end
end
