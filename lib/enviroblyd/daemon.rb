# frozen_string_literal: true

require "socket"
require "json"

class Enviroblyd::Daemon
  MAX_MESSAGE_SIZE = 6000 # bytes
  LISTEN_PORT = ENV.fetch("ENVIROBLYD_PORT", 63106).to_i

  def self.start
    imds = Enviroblyd::IMDS.new
    host = imds.private_ipv4
    new.listen(host) do
      Enviroblyd::Web.register
    end
  end

  def listen(host)
    server = TCPServer.new host, LISTEN_PORT
    puts "Listening on #{host}:#{LISTEN_PORT}"

    yield

    loop do
      Thread.start(server.accept) do |client|
        params =
          begin
            JSON.parse client.recv(MAX_MESSAGE_SIZE)
          rescue
            :invalid_json
          end

        if params == :invalid_json
          client.puts "Error parsing JSON"
        else
          client.puts "OK"
        end

        client.close
        Enviroblyd::Command.run(params)
      end
    end
  end
end
