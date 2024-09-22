# frozen_string_literal: true

require "net/http"
require "uri"
require "fileutils"
require "pathname"
require "json"

class Enviroblyd::Web
  USER_AGENT = "enviroblyd #{Enviroblyd::VERSION}"
  CONTENT_TYPE = "application/json"
  WORKING_DIR = Pathname.new ENV.fetch("ENVIROBLYD_WORKING_DIR", "/var/envirobly/daemon")
  INITIALIZED_FILE = WORKING_DIR.join "initialized"

  class << self
    def register
      if File.exist?(INITIALIZED_FILE)
        puts "Skipping initialization because #{INITIALIZED_FILE} exists."
      else
        init_url = ENV.fetch "ENVIROBLYD_INIT_URL"
        puts "Init URL: #{init_url}"
        response = http(init_url, type: Net::HTTP::Put)
        puts "Init response code: #{response.code}"

        if response.code.to_i == 200
          FileUtils.mkdir_p WORKING_DIR
          File.write INITIALIZED_FILE, init_url
        end
      end
    end

    def http(url, type: Net::HTTP::Get, params: nil, headers: {}, retry_interval: 3, retries: 10, backoff: :exponential, tries: 1)
      if retries <= tries
        puts "Retried #{url} #{tries} times. Aborting."
        return
      end

      uri = URI(url)
      http = Net::HTTP.new uri.host, uri.port
      http.use_ssl = true if uri.scheme == "https"
      http.open_timeout = 10
      http.read_timeout = 10

      request = type.new(uri, default_headers.merge(headers))
      request.content_type = CONTENT_TYPE
      request.body = JSON.dump(params) unless params.nil?

      response =
        begin
          http.request(request)
        rescue
          nil
        end

      if response.nil? || (500..599).include?(response.code.to_i)
        sleep_time = (backoff == :exponential) ? (retry_interval * tries) : retry_interval
        puts "Retry #{uri} in #{sleep_time}s"
        sleep sleep_time
        http(url, type:, params:, retry_interval:, retries:, backoff:, tries: (tries + 1))
      else
        response
      end
    end

    private
      def default_headers
        { "User-Agent" => USER_AGENT }
      end
  end
end
