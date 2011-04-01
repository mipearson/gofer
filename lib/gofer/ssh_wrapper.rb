require 'net/ssh'

module Gofer
  class SshWrapper

    attr_reader :last_output, :last_exit_status

    def initialize username, hostname, identity_file = nil
      @username = username
      @hostname = hostname
      @identity_file = identity_file
      @last_exit_status = nil
      @last_output = nil
    end

    def run command, opts={}
      Net::SSH.start(*net_ssh_credentials) do |ssh|
        ssh_execute(ssh, command, opts)
      end
    end

    private
  
    def net_ssh_credentials
      creds = [@hostname, @username]
      creds << {:keys => [@identity_file] } if @identity_file
      creds
    end

    def ssh_execute(ssh, command, opts={})
      output = ''
      exit_code = 0
      ssh.open_channel do |channel|
        channel.exec(command) do |ch, success|
          unless success
            raise "Couldn't execute command #{command} (ssh channel failure)"
          end

          channel.on_data do |ch, data|  # stdout
            output += data
            $stdout.print data unless opts[:quiet]
          end

          channel.on_extended_data do |ch, type, data|
            next unless type == 1 # only handle stderr
            output += data if opts[:capture_stderr]
            $stderr.print data unless opts[:quiet_stderr]
          end

          channel.on_request("exit-status") do |ch, data|
            exit_code = data.read_long
            channel.close # Necessary or backgrounded processes will 'hang' the channel
          end
          
        end
      end

      ssh.loop
      
      @last_exit_status = exit_code
      @last_output = output
    end
  end
end
