# frozen_string_literal: true
require "net/http"
require "uri"

class Enviroblyd::Cli::Main < Enviroblyd::Base
  desc "version", "Show version"
  def version
    puts Enviroblyd::VERSION
  end

  TOKEN_TTL_SECONDS = 30
  IMDS_HOST = ENV.fetch("ENVIROBLYD_IMDS_HOST", "169.254.169.254")
  API_HOST = ENV.fetch("ENVIROBLYD_API_HOST", "envirobly.com")
  desc "boot", "Get IMDSv2 metadata"
  def boot
    token = http("http://#{IMDS_HOST}/latest/api/token").body.chomp("")
    puts "token: #{token} ."
    instance_id =  http("http://#{IMDS_HOST}/latest/meta-data/instance-id").body.chomp("")
    puts "instance_id: #{instance_id} ."

    response = http("https://#{API_HOST}/api/v1/boots/#{instance_id}", retry_interval: 3, retries: 5, backoff: :exponential)
    puts "/api/v1/boots response code: #{response.code}"
  end

  private
    def http(url, type: Net::HTTP::Get, headers: {}, retry_interval: 1, retries: 30, backoff: false, success_codes: 200..299, tries: 1)
      uri = URI(url)
      http = Net::HTTP.new uri.host, uri.port
      http.use_ssl = true if uri.scheme == "https"
      http.open_timeout = 5
      http.read_timeout = 5

      request = type.new(uri, headers)
      # request.content_type = CONTENT_TYPE

      yield request if block_given?

      response = http.request(request)
      if success_codes.include?(response.code.to_i)
        response
      elsif retries <= tries
        $stderr.puts "Retried #{tries} times. Aborting."
        exit 1
      else
        sleep_time = (backoff == :exponential) ? (retry_interval * tries) : retry_interval
        puts "Try #{uri} in #{sleep_time}s"
        sleep sleep_time
        http(url, type:, retry_interval:, retries:, backoff:, success_codes:, tries: (tries + 1))
      end
    end
end
