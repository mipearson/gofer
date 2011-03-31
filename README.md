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

      puts read('a_remote_file')
      puts ls('a_remote_dir').join(", ")

      # error handling - default to critical failure if a command fails
      run "false" # this will fail
      run "false", :capture_exit_status => true # this won't ...
      puts last_exit_status # and will make the exit status available

      # stderr/stdout
      hello = run "echo hello" # will print 'Host my.host.com> hello'
      puts hello # will print "hello\n"
      # stdout/stderr will be interpolated for simplicity

    end

    # alternate usage:
    h = Gofer::Host.new('ubuntu', 'my.host.com')
    h.run('sudo mysqld stop')
    h.upload('file', 'remote_file')
    # etc..

### Later:

    # output capture
    run "echo goodbye", :quiet => true # won't print anything
  
    # overriding defaults
    set :quiet => true
    set :capture_exit_status => false

    # Separate the command from the arguments, system() style
    run "echo" "Some" "arguments" "with" "'quotes'" "in" "them"
    
    # Local system usage, too:
    run "hostname" # > my.macbook.com

