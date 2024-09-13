# frozen_string_literal: true

class Enviroblyd::IMDS
  TOKEN_TTL_SECONDS = 30
  IMDS_HOST = ENV.fetch("ENVIROBLYD_IMDS_HOST", "169.254.169.254")

  def initialize
    @token = Enviroblyd::Web.http("http://#{IMDS_HOST}/latest/api/token",
      type: Net::HTTP::Get,
      headers: { "X-aws-ec2-metadata-token-ttl-seconds" => TOKEN_TTL_SECONDS.to_s }).
      body.strip
  end

  def get(key)
    Enviroblyd::Web.http("http://#{IMDS_HOST}/latest/meta-data/#{key}",
      headers: { "X-aws-ec2-metadata-token" => @token }).
      body.strip
  end

  def private_ipv4
    get "local-ipv4"
  end
end
