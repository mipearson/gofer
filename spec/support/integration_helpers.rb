module IntegrationHelpers

  def test_hostname
    ENV['TEST_HOST'] || 'localhost'
  end

  def test_username
    ENV['TEST_USER'] || ENV['USER']
  end

  def test_identity_file
    ENV['TEST_IDENTITY_FILE'] || '~/.ssh/id_rsa'
  end

  def raw_ssh command
    out = `ssh -o PasswordAuthentication=no -ni #{test_identity_file} #{test_username}@#{test_hostname} #{command}`
    raise "Command #{command} failed" unless $? == 0
    out
  end

  def make_tmpdir
    @tmpdir = raw_ssh("mktemp -d /tmp/gofertest.XXXXX").chomp
  end

  def clean_tmpdir
    if ENV['KEEPTMPDIR']
      puts "TMPDIR is #{@tmpdir}"
    else
      raw_ssh "rm -rf #{@tmpdir}" if @tmpdir && @tmpdir =~ %r{gofertest}
    end
  end

  def in_tmpdir path
    File.join(@tmpdir, path)
  end

  def with_local_tmpdir template
    f = Tempfile.new template
    path = f.path
    f.unlink
    FileUtils.mkdir path
    begin
      yield path
    ensure
      FileUtils.rm_rf path unless ENV['KEEPTMPDIR']
    end
  end

  def with_captured_output
    @stdout = ''
    @stderr = ''
    @combined = ''
    $stdout.stub!( :write ) { |*args| @stdout.<<( *args ); @combined.<<( *args )}
    $stderr.stub!( :write ) { |*args| @stderr.<<( *args ); @combined.<<( *args )}
  end
end
