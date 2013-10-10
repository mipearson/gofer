require 'net/ssh'
require 'net/scp'

module Gofer
  class SshWrapper # :nodoc:

    attr_reader :last_output, :last_exit_status

    def initialize *args
      @net_ssh_args = args
      @at_start_of_line = true
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
      @ssh ||= Net::SSH.start(*@net_ssh_args)
    end

    def scp
      @scp ||= Net::SCP.new(ssh)
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
            $stdout.print wrap_output(data, opts[:output_prefix]) unless opts[:quiet]
          end

          channel.on_extended_data do |ch, type, data|
            next unless type == 1 # only handle stderr
            stderr += data
            output += data
            $stderr.print wrap_output(data, opts[:output_prefix]) unless opts[:quiet_stderr]
          end

          channel.on_request("exit-status") do |ch, data|
            exit_code = data.read_long
            channel.close # Necessary or backgrounded processes will 'hang' the channel
          end

          if opts[:stdin]
            channel.send_data(opts[:stdin])
            channel.eof!
          end

        end
      end

      ssh.loop
      Gofer::Response.new(stdout, stderr, output, exit_code)
    end

    def wrap_output output, prefix
      return output unless prefix

      output = "#{prefix}: " + output if @at_start_of_line

      @at_start_of_line = output.end_with?("\n")

      output.gsub(/\n(.)/, "\n#{prefix}: \\1")
    end

  end
end
