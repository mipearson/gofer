require 'tempfile'

module Gofer
  # A persistent, authenticated SSH connection to a single host.
  #
  # Connections are persistent, but not encapsulated within a shell.
  # This means that while it won't need to reconnect & re-authenticate for
  # each operation, don't assume that environment variables will be
  # persisted between commands like they will in a shell-based SSH session.
  #
  # +/etc/ssh/config+ and <tt>~/.ssh/config</tt> are not recognized by Net::SSH, and thus
  # not recognized by Gofer::Host.

  class Host

    attr_reader :hostname
    attr_accessor :quiet, :output_prefix

    # Create a new connection to a host
    #
    # Passed options not included in the below are passed directly to
    # <tt>Net::SSH.start</tt>. See http://net-ssh.github.com/ssh/v2/api/index.html
    # for valid arguments.
    #
    # Options:
    #
    # +quiet+:: Don't print stdout output from +run+ commands
    # +output_prefix+:: Prefix each line of stdout and stderr to differentiate multiple host output
    def initialize _hostname, username, opts={}
      @hostname = _hostname

      # support legacy positional argument use
      if opts.is_a? String
        warn "Gofer::Host.new identify file positional argument will be removed in 1.0, use :keys instead"
        opts = { :keys => [opts]}
      end

      @quiet = opts.delete(:quiet)
      @output_prefix = opts.delete(:output_prefix)

      # support legacy identity_file argument
      if opts[:identity_file]
        warn "Gofer::Host.new option :identify_file will be removed in 1.0, use :keys instead"
        opts[:keys] = [opts.delete(:identity_file)]
      end

      @ssh = SshWrapper.new(hostname, username, opts)
    end

    # Run +command+.
    #
    # Will raise an error if +command+ exits with a non-zero status, unless
    # +capture_exit_status+ is true.
    #
    # Print +stdout+ and +stderr+ as they're received.
    #
    # Returns an intance of Gofer::Response, containing captured +stdout+,
    # +stderr+, and an exit status if +capture_exit_status+ is true.
    #
    # Options:
    #
    # +quiet+:: Don't print +stdout+, can also be set with +quiet=+ on the instance
    # +quiet_stderr+:: Don't print +stderr+
    # +capture_exit_status+:: Don't raise an error on a non-zero exit status
    def run command, opts={}
      opts[:quiet] = quiet unless opts.include?(:quiet)
      opts[:output_prefix] = @output_prefix
      response = @ssh.run command, opts
      if !opts[:capture_exit_status] && response.exit_status != 0
        raise HostError.new(self, response, "Command #{command} failed with exit status #{@ssh.last_exit_status}")
      end
      response
    end

    # Returns +true+ if +path+ exists, +false+ otherwise.
    def exist? path
      @ssh.run("sh -c '[ -e #{path} ]'").exit_status == 0
    end

    # Returnss the contents of the file at +path+.
    def read path
      @ssh.read_file path
    end

    # Returns +true+ if +path+ is a directory, +false+ otherwise.
    def directory? path
      @ssh.run("sh -c '[ -d #{path} ]'").exit_status == 0
    end

    # Returns a list of the files in the directory at +path+.
    def ls path
      response = @ssh.run "ls -1 #{path}", :quiet => true
      if response.exit_status == 0
        response.stdout.strip.split("\n")
      else
        raise HostError.new(self, response, "Could not list #{path}, exit status #{response.exit_status}")
      end
    end

    # Uploads the file or directory at +from+ to +to+.
    #
    # Options:
    #
    # +recursive+: Perform a recursive upload, similar to +scp -r+. +true+ by default if +from+ is a directory.
    def upload from, to, opts = {}
      @ssh.upload from, to, {:recursive => File.directory?(from)}.merge(opts)
    end

    # Downloads the file or directory at +from+ to +to+
    #
    # Options:
    #
    # +recursive+: Perform a recursive download, similar to +scp -r+. +true+ by default if +from+ is a directory.
    def download from, to, opts = {}
      @ssh.download from, to, {:recursive => directory?(from)}.merge(opts)
    end

    # Writes +data+ to a file at +to+
    def write data, to
      Tempfile.open "gofer_write" do |file|
        file.write data
        file.close
        @ssh.upload(file.path, to, :recursive => false)
      end
    end
  end
end
