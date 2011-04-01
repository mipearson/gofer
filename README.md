# Gofer!

### Now:

    # Remote system usage
    Gofer::Host.new('ubuntu', 'my.host.com', :identity_file => 'key.pem').within do
      # Basic usage
      run "sudo stop mysqld"

      # Copying files
      upload 'file' 'remote_file'
      download 'remote_dir', 'dir'

      # Filesystem inspection
      if exists?('remote_directory')
        run "rm -rf 'remote_directory'"
      end

      # read/ls
      puts read('a_remote_file')
      puts ls('a_remote_dir').join(", ")

      # error handling - default to critical failure if a command fails
      run "false" # this will fail
      run "false", :capture_exit_status => true # this won't ...
      puts last_exit_status # and will make the exit status available

      # stderr/stdout
      hello = run "echo hello" # will print 'hello'
      puts hello # will print "hello\n"

      goodbye = run "echo goodbye 1>&2"
      # goodbye will be empty, as we don't capture stderr by default
  
      goodbye = run "echo goodbye 1>&2", :capture_stderr => true # unless you ask for it

      # output suppression
      run "echo noisy", :quiet => true  # don't output from our command
      run "echo noisier 1>&2", :quiet_stderr => true # don't even output stderr!

    end

    # alternate usage:
    h = Gofer::Host.new('ubuntu', 'my.host.com')
    h.run('sudo mysqld stop')
    h.upload('file', 'remote_file')
    # etc..

### Later:

    write("a string buffer", 'a_remote_file')
    # constant connection (no reconnect for each action)
    h = Gofer::Host.new(..., :keep_open => true)
    h.run( ... )
    h.close

    # overriding defaults
    set :quiet => true
    set :capture_exit_status => false

    # Separate the command from the arguments, system() style
    run "echo" "Some" "arguments" "with" "'quotes'" "in" "them"
    
    # Local system usage, too:
    run "hostname" # > my.macbook.com


