# frozen_string_literal: true

require "open3"
require "json"

class Enviroblyd::Command
  DEFAULT_TIMEOUT_SECONDS = 5 * 60
  DEFAULT_RUNTIME = "/bin/bash"

  def initialize(message)
    params = parse_message message
    @url = params.fetch "url"
    @script = params.fetch "script"
    @runtime = params.fetch "runtime", DEFAULT_RUNTIME
    @timeout = params.fetch "timeout", DEFAULT_TIMEOUT_SECONDS
    @stdout = @stderr = @exit_code = nil
    @valid = true
  rescue NoMethodError, KeyError
    @valid = false
  end

  def valid?
    @valid
  end

  def run
    puts "Command #{@url} starting"
    Open3.popen3("timeout #{@timeout} #{@runtime}") do |stdin, stdout, stderr, thread|
      stdin.puts @script
      stdin.close
      @stdout = stdout.read
      @stderr = stderr.read
      @exit_code = thread.value.exitstatus
    end
    puts "Command #{@url} exited with #{@exit_code}"
    $stdout.flush

    Enviroblyd::Web.http(@url, type: Net::HTTP::Put, params: to_complete_params)
  end

  private
    def to_complete_params
      {
        command: {
          stdout: @stdout,
          stderr: @stderr,
          exit_code: @exit_code
        }
      }
    end

    def parse_message(message)
      JSON.parse message
    rescue
      nil
    end
end
