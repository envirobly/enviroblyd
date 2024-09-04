# frozen_string_literal: true
require "net/http"
require "uri"
require "open3"
require "fileutils"
require "pathname"

class Enviroblyd::Cli::Main < Enviroblyd::Base
  desc "version", "Show version"
  def version
    puts Enviroblyd::VERSION
  end

  TOKEN_TTL_SECONDS = 30
  IMDS_HOST = ENV.fetch("ENVIROBLYD_IMDS_HOST", "169.254.169.254")
  API_HOST = ENV.fetch("ENVIROBLYD_API_HOST", "envirobly.com")
  INIT_URL = ENV.fetch("ENVIROBLYD_INIT_URL")
  WORKING_DIR = Pathname.new ENV.fetch("ENVIROBLYD_WORKING_DIR", "/var/envirobly/daemon")
  INITIALIZED_FILE = WORKING_DIR.join "initialized"
  desc "boot", "Start the daemon"
  def boot
    # @token = http("http://#{IMDS_HOST}/latest/api/token",
    #   type: Net::HTTP::Put, headers: { "X-aws-ec2-metadata-token-ttl-seconds" => TOKEN_TTL_SECONDS.to_s }).
    #   body.chomp("")
    # puts "token: #{@token} ."
    # instance_id = http("http://#{IMDS_HOST}/latest/meta-data/instance-id",
    #   headers: { "X-aws-ec2-metadata-token" => @token }).
    #   body.chomp("")
    # puts "instance_id: #{instance_id} ."
    #
    # response = http("https://#{API_HOST}/api/v1/boots/#{instance_id}", retry_interval: 3, retries: 5, backoff: :exponential)
    # puts "/api/v1/boots response code: #{response.code}"

    if File.exist?(INITIALIZED_FILE)
      puts "Skipping initialization because #{INITIALIZED_FILE} exists."
    else
      puts "Init URL: #{INIT_URL}"
      response = http(INIT_URL, type: Net::HTTP::Put, retry_interval: 3, retries: 10, backoff: :exponential)
      puts "Init response code: #{response.code}"

      FileUtils.mkdir_p WORKING_DIR
      File.write INITIALIZED_FILE, INIT_URL
    end
  end

  private
    def http(url, type: Net::HTTP::Get, headers: {}, retry_interval: 2, retries: 30, backoff: false, success_codes: 200..299, tries: 1)
      uri = URI(url)
      http = Net::HTTP.new uri.host, uri.port
      http.use_ssl = true if uri.scheme == "https"
      http.open_timeout = 5
      http.read_timeout = 5

      request = type.new(uri, default_headers.merge(headers))
      # request.content_type = CONTENT_TYPE

      yield request if block_given?

      response =
        begin
          http.request(request)
        rescue
          nil
        end

      if response && success_codes.include?(response.code.to_i)
        response
      elsif retries <= tries
        $stderr.puts "Retried #{tries} times. Aborting."
        exit 1
      else
        sleep_time = (backoff == :exponential) ? (retry_interval * tries) : retry_interval
        $stderr.puts "Retry #{uri} in #{sleep_time}s"
        sleep sleep_time
        http(url, type:, retry_interval:, retries:, backoff:, success_codes:, tries: (tries + 1))
      end
    end

    RUN_TIMEOUT = "5m"
    def run(script)
      @stdout = @stderr = @exit_code = nil
      Open3.popen3("timeout #{RUN_TIMEOUT} /bin/bash") do |stdin, stdout, stderr, thread|
        stdin.puts script
        stdin.close
        @stdout = stdout.read
        @stderr = stderr.read
        @exit_code = thread.value.exitstatus
      end
    end

    USER_AGENT = "enviroblyd #{Enviroblyd::VERSION}"
    def default_headers
      { "User-Agent" => USER_AGENT }
    end
end
