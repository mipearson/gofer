# Gofer!

**Gofer** is a set of wrappers around the Net::SSH suite of tools to enable consistent access to remote systems.

**Gofer** has been written to support the needs of system automation scripts. As such, **gofer** will:

  * automatically raise an error if a command returns a non-zero exit status
  * print and capture STDOUT and STDERR automatically
  * allow you to access captured STDOUT and STDERR individually or as a combined string
  * override the above: return non-zero exit status instead of raising an error, suppress output

## Examples

    h = Gofer::Host.new('ubuntu', 'my.host.com', :identity_file => 'key.pem')

    # Basic usage
    h.run "sudo stop mysqld"

    # Copying files
    h.upload 'file' 'remote_file'
    h.download 'remote_dir', 'dir'

    # Filesystem inspection
    if h.exists?('remote_directory')
      h.run "rm -rf 'remote_directory'"
    end

    # read/ls
    puts h.read('a_remote_file')
    puts h.ls('a_remote_dir').join(", ")

    # error handling - default to critical failure if a command fails
    h.run "false" # this will fail
    response = h.run "false", :capture_exit_status => true # this won't ...
    puts response.exit_status # and will make the exit status available

    # stderr/stdout
    response = h.run "echo hello; echo goodbye 1>&2\n"
    puts response         # will print "hello\n"
    puts response.stdout  # will also print "hello\n"
    puts response.stderr  # will print "goodbye\n"
    puts response.output  # will print "hello\ngoodbye\n"

    # output suppression
    h.run "echo noisy", :quiet => true  # don't output from our command
    h.run "echo noisier 1>&2", :quiet_stderr => true # don't even output stderr!

## Planned Features

    h.write("a string buffer", 'a_remote_file')
    # constant connection (no reconnect for each action)
    Gofer::Host.new(...).open do |h|
      h.run( ... )
    end
    
    # overriding defaults
    h.set :quiet => true
    h.set :capture_exit_status => false

    # Separate the command from the arguments, system() style
    h.run "echo" "Some" "arguments" "with" "'quotes'" "in" "them"
    
    # Local system usage, too:
    Gofer::Localhost.new.run "hostname" # > my.macbook.com

## Testing
  
  * Ensure that your user can ssh as itself to localhost using the key in `~/.ssh/id_rsa`.
  * Run `rspec spec` or `bundle install && rake spec`

## TODO
 
* ls, exists?, directory? should use sftp if available rather than shell commands
* wrap STDOUT with host prefix for easy identification of system output

## License

(The MIT License)

Copyright (c) 2011 Michael Pearson

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
