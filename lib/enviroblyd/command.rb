# frozen_string_literal: true

require "open3"

class Enviroblyd::Command
  DEFAULT_TIMEOUT_SECONDS = 5 * 60
  DEFAULT_RUNTIME = "/bin/bash"

  def initialize(params)
    @script = params.fetch "script"
    @runtime = params.fetch "runtime", DEFAULT_RUNTIME
    @timeout = params.fetch "timeout", DEFAULT_TIMEOUT_SECONDS
    @stdout = @stderr = @exit_code = nil
  end

  def run
    puts "Command starting"

    Open3.popen3("timeout #{@timeout} #{@runtime}") do |stdin, stdout, stderr, thread|
      stdin.puts @script
      stdin.close
      @stdout = stdout.read
      @stderr = stderr.read
      @exit_code = thread.value.exitstatus
    end

    puts "Command finished"
    puts @stdout
    puts @stderr
  end
end
