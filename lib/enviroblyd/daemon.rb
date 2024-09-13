# frozen_string_literal: true

require "socket"
require "json"

class Enviroblyd::Daemon
  MAX_MESSAGE_SIZE = 6000 # bytes
  LISTEN_PORT = ENV.fetch("ENVIROBLYD_PORT", 63106).to_i

  def self.start
    imds = Enviroblyd::IMDS.new
    host = imds.private_ipv4
    daemon = new(host)
    daemon.listen
  end

  def initialize(host)
    @host = host
  end

  def listen
    server = TCPServer.new @host, LISTEN_PORT
    puts "Listening on #{@host}:#{LISTEN_PORT}"
    Enviroblyd::Web.register

    loop do
      Thread.start(server.accept) do |client|
        params =
          begin
            JSON.parse client.recv(MAX_MESSAGE_SIZE)
          rescue
            nil
          end

        if params.nil?
          client.puts "Error parsing JSON"
          client.close
        else
          client.puts "OK"
          client.close

          command = Enviroblyd::Command.new(params)
          command.run
        end
      end
    end
  end
end
