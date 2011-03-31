# Gofer!

### Example:

    # Remote system usage
    Host.new('ubuntu', 'my.host.com', :identity_file => 'key.pem').within do
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
      run "false" # this will fail with 'Non-zero return code of 1'
      run "false", :ignore_return_code => true # this won't ...
      puts $? # and will set $?

      # Separate the command from the arguments, system() style
      run "echo" "Some" "arguments" "with" "'quotes'" "in" "them"

      # stderr/stdout
      hello = run "echo hello" # will print 'Host my.host.com> hello'
      puts hello # will print "hello\n"
      # stdout/stderr will be interpolated for simplicity

      # output capture
      run "echo goodbye", :quiet => true # won't print anything
    end

    # alternate usage:
    h = Host.new('ubuntu', 'my.host.com')
    h.run('sudo mysqld stop')
    h.upload('file', 'remote_file')
    # etc..

    # Local system usage, too:
    run "hostname" # > my.macbook.com
