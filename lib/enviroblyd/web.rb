# frozen_string_literal: true

require "net/http"
require "uri"
require "open3"
require "fileutils"
require "pathname"
require "json"

class Enviroblyd::Web
  USER_AGENT = "enviroblyd #{Enviroblyd::VERSION}"
  CONTENT_TYPE = "application/json"
  # TOKEN_TTL_SECONDS = 30
  # IMDS_HOST = ENV.fetch("ENVIROBLYD_IMDS_HOST", "169.254.169.254")
  API_HOST = ENV.fetch("ENVIROBLYD_API_HOST", "envirobly.com")
  WORKING_DIR = Pathname.new ENV.fetch("ENVIROBLYD_WORKING_DIR", "/var/envirobly/daemon")
  INITIALIZED_FILE = WORKING_DIR.join "initialized"

  def register
    if File.exist?(INITIALIZED_FILE)
      puts "Skipping initialization because #{INITIALIZED_FILE} exists."
    else
      init_url = ENV.fetch "ENVIROBLYD_INIT_URL"
      puts "Init URL: #{init_url}"
      response = http(init_url, type: Net::HTTP::Put, retry_interval: 3, retries: 10, backoff: :exponential)
      puts "Init response code: #{response.code}"

      if response.code.to_i == 200
        FileUtils.mkdir_p WORKING_DIR
        File.write INITIALIZED_FILE, init_url
      end
    end
  end

  def http(url, type: Net::HTTP::Get, headers: {}, retry_interval: 2, retries: 30, backoff: false, tries: 1, params: nil)
    if retries <= tries
      $stderr.puts "Retried #{tries} times. Aborting."
      exit 1
    end

    uri = URI(url)
    http = Net::HTTP.new uri.host, uri.port
    http.use_ssl = true if uri.scheme == "https"
    http.open_timeout = 5
    http.read_timeout = 5

    request = type.new(uri, default_headers.merge(headers))
    request.content_type = CONTENT_TYPE

    unless params.nil?
      request.body = JSON.dump params
    end

    response =
      begin
        http.request(request)
      rescue
        :retry
      end

    # https://developers.cloudflare.com/support/troubleshooting/cloudflare-errors/troubleshooting-cloudflare-1xxx-errors/
    if response == :retry || (500..599).include?(response.code.to_i)
      sleep_time = (backoff == :exponential) ? (retry_interval * tries) : retry_interval
      $stderr.puts "Retry #{uri} in #{sleep_time}s"
      sleep sleep_time
      http(url, type:, retry_interval:, retries:, backoff:, tries: (tries + 1))
    else
      response
    end
  end

  private
    def default_headers
      { "User-Agent" => USER_AGENT }
    end
end
