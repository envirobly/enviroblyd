# frozen_string_literal: true

class Enviroblyd::Cli::Main < Enviroblyd::Base
  desc "version", "Show version"
  def version
    puts Enviroblyd::VERSION
  end

  TOKEN_TTL_SECONDS = 30
  IMDS_HOST = ENV.fetch("ENVIROBLYD_IMDS_HOST", "[fd00:ec2::254]")
  desc "metadata", "Get IMDSv2 metadata"
  def metadata
    token = `curl -s -X PUT "http://#{IMDS_HOST}/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: #{TOKEN_TTL_SECONDS}"`
    puts "token: #{token}"
    instance_id = `curl -s -H "X-aws-ec2-metadata-token: #{token}" http://#{IMDS_HOST}/latest/meta-data/instance-id`
    puts "instance_id: #{instance_id}"
  end
end
