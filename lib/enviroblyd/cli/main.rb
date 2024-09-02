# frozen_string_literal: true
require "net/http"
require "uri"

class Enviroblyd::Cli::Main < Enviroblyd::Base
  desc "version", "Show version"
  def version
    puts Enviroblyd::VERSION
  end

  TOKEN_TTL_SECONDS = 30
  IMDS_HOST = ENV.fetch("ENVIROBLYD_IMDS_HOST", "[fd00:ec2::254]")
  desc "metadata", "Get IMDSv2 metadata"
  def metadata
    token = http("http://#{IMDS_HOST}/latest/api/token").body.chomp("")
    puts "token: #{token} ."
    instance_id =  http("http://#{IMDS_HOST}/latest/meta-data/instance-id").body.chomp("")
    puts "instance_id: #{instance_id} ."
  end

  private
    def http(url, type: Net::HTTP::Get, headers: {}, retry_interval: 1, retries: 30, success_codes: 200..299, tries: 0)
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
        sleep retry_interval
        http(url, type:, retry_interval:, retries:, success_codes:, tries: (tries + 1))
      end
    end
end
