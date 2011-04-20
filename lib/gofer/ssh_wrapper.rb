require 'net/ssh'
require 'net/scp'

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
      response = nil
      Net::SSH.start(*net_ssh_credentials) do |ssh|
        response = ssh_execute(ssh, command, opts)
      end
      response
    end
    
    def read_file path
      a = nil
      with_scp do |scp|
        a = scp.download! path
      end
      a
    end

    def download from, to, opts={}
      with_scp do |scp|
        scp.download! from, to, opts
      end
    end

    def upload from, to, opts={}
      with_scp do |scp|
        scp.upload! from, to, opts
      end
    end

    private
  
    def with_scp 
      Net::SCP.start(*net_ssh_credentials) do |scp|
        yield scp
      end
    end

    def net_ssh_credentials
      creds = [@hostname, @username]
      creds << {:keys => [@identity_file] } if @identity_file
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
