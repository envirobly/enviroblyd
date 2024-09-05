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
        message = client.recv(MAX_MESSAGE_SIZE)

        params =
          begin
            JSON.parse message
          rescue
            nil
          end

        if params.nil?
          client.puts "Error parsing JSON"
        else
          puts "Received valid JSON:"
          puts params
          client.puts "OK"
        end

        # TODO: Handle Broken pipe (Errno::EPIPE) (client closing connection before we write back)
        client.close

        Thread.new do
          Enviroblyd::Command.new(params).run
        end
      end
    end
  end
end
