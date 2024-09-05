# frozen_string_literal: true

require "socket"
require "json"

class Enviroblyd::Daemon
  MAX_MESSAGE_SIZE = 6000 # bytes
  LISTEN_PORT = ENV.fetch("ENVIROBLYD_PORT", 63106).to_i

  def self.start
    daemon = new
    daemon.listen

    web = Enviroblyd::Web.new
    web.register
  end

  def listen
    server = TCPServer.new LISTEN_PORT
    puts "Listening on port #{LISTEN_PORT}"

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
