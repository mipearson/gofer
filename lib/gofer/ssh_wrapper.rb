require 'net/ssh'
require 'net/scp'

module Gofer
  class SshWrapper # :nodoc:

    attr_reader :last_output, :last_exit_status

    def initialize username, hostname, opts={}
      @username = username
      @hostname = hostname
      @last_exit_status = nil
      @last_output = nil
      
      # support legacy positional argument use
      if opts.is_a? String
        opts = { :keys => [opts]}
      end
      
      # support legacy identity_file argument
      if opts[:identity_file]
        opts[:keys] = [opts.delete(:identity_file)]
      end
      
      @net_ssh_options = opts
    end

    def run command, opts={}
      ssh_execute(ssh, command, opts)
    end
    
    def read_file path
      scp.download! path
    end

    def download from, to, opts={}
      scp.download! from, to, opts
    end

    def upload from, to, opts={}
      scp.upload! from, to, opts
    end

    private
  
    def ssh
      @ssh ||= Net::SSH.start(*net_ssh_credentials)
    end
    
    def scp 
      @scp ||= Net::SCP.new(ssh)
    end

    def net_ssh_credentials
      creds = [@hostname, @username, @net_ssh_options]
      creds
    end

    def ssh_execute(ssh, command, opts={})
      stdout, stderr, output = '', '', ''
      exit_code = 0
      ssh.open_channel do |channel|
        channel.exec(command) do |ch, success|
          unless success
            raise "Couldn't execute command #{command} (ssh channel failure)"
          end

          channel.on_data do |ch, data|  # stdout
            stdout += data
            output += data
            $stdout.print data unless opts[:quiet]
          end

          channel.on_extended_data do |ch, type, data|
            next unless type == 1 # only handle stderr
            stderr += data
            output += data
            $stderr.print data unless opts[:quiet_stderr]
          end

          channel.on_request("exit-status") do |ch, data|
            exit_code = data.read_long
            channel.close # Necessary or backgrounded processes will 'hang' the channel
          end
          
        end
      end

      ssh.loop
      Gofer::Response.new(stdout, stderr, output, exit_code)
    end
  end
end
