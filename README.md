# Gofer!

**Gofer** is a set of wrappers around the Net::SSH suite of tools to enable consistent access to remote systems.

**Gofer** has been written to support the needs of system automation scripts. As such, **gofer** will:

  * automatically raise an error if a command returns a non-zero exit status
  * print and capture STDOUT and STDERR automatically
  * allow you to access captured STDOUT and STDERR individually or as a combined string
  * override the above: return non-zero exit status instead of raising an error, suppress output
  * persist the SSH connection so that multiple commands don't incur connection penalties

## Examples

### Instantiation

``` ruby
h = Gofer::Host.new('my.host.com', 'ubuntu', :keys => ['key.pem'])
```

### Run a command

``` ruby
h.run "sudo stop mysqld"
```

### Copy some files

``` ruby
h.upload 'file', 'remote_file'
h.download 'remote_dir', 'dir'
```

### Interact with the filesystem

``` ruby
if h.exist?('remote_directory')
  h.run "rm -rf 'remote_directory'"
end

h.write("a string buffer", 'a_remote_file')
puts h.read('a_remote_file')
puts h.ls('a_remote_dir').join(", ")
```

### Respond to command errors

``` ruby
h.run "false" # this will raise an error
response = h.run "false", :capture_exit_status => true # this won't ...
puts response.exit_status # and will make the exit status available
```

### Capture output

``` ruby
response = h.run "echo hello; echo goodbye 1>&2\n"
puts response         # will print "hello\n"
puts response.stdout  # will also print "hello\n"
puts response.stderr  # will print "goodbye\n"
puts response.output  # will print "hello\ngoodbye\n"
```

### Prefix output

``` ruby
h.output_prefix = 'apollo'        # or set :output_prefix on instantiation
h.run "echo hello; echo goodbye"  # prints apollo: hello\napollo: goodbye
```

### Suppress output

``` ruby
h.run "echo noisy", :quiet => true               # don't print stdout
h.run "echo noisier 1>&2", :quiet_stderr => true # don't print stderr
h.quiet = true                                   # never print stdout
```

### Run multiple commands

``` ruby
response = h.run_multiple(['echo hello', 'echo goodbye'], :quiet => true)
puts response.stdout # will print "hello\ngoodbye\n"
```

### Run the same commands on multiple hosts

``` ruby
cluster = Gopher::Cluster.new
cluster << Gofer::Host.new('my.host.com', 'ubuntu', :keys => ['key.pem'], :output_prefix => "   my")
cluster << Gofer::Host.new('other.host.com', 'ubuntu', :keys => ['key.pem'], :output_prefix => "other")

cluster.run do |c|
    c.run("hostname") # This will run on both hosts at once
end

cluster.run(:max_concurrency => 1) do |c|
    c.run("sudo /etc/init.d/apache2 restart") # This will run on one machine at a time
end
```

### Run a command on only one host

```
cluster = Gopher::Cluster.new
cluster << Gofer::Host.new('my.host.com', 'ubuntu', :keys => ['key.pem'], :output_prefix => "host1")
cluster << Gofer::Host.new('other.host.com', 'ubuntu', :keys => ['key.pem'], :output_prefix => "host2")

cluster.run_once("rake migrations") # Run migrations on only a single host
```


## Testing

  * Ensure that your user can ssh as itself to localhost using the key in `~/.ssh/id_rsa`.
  * Run `rspec spec` or `bundle install && rake spec`

## Contributing

Contributions should be via pull request. Please add tests and a note in the
`README.md` for new functionality. Please use 1.8.7-compatiable syntax.

## TODO

  * ls, exists?, directory? should use sftp if available rather than shell commands
  * Deal with timeouts/disconnects on persistent connections
  * Release 1.0 & use Semver
  * Ensure RDodc is complete & up to date, link to rdoc.info from README
  * Add unit tests, bring in Travis.ci
  * Local system usage (eg `Gofer::Localhost.new.run "hostname"`)

## License

(The MIT License)

Copyright (c) 2011-13 Michael Pearson

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
