# frozen_string_literal: true

require "socket"

class Enviroblyd::Daemon
  MAX_MESSAGE_SIZE = 6000 # bytes
  PORT = ENV.fetch("ENVIROBLYD_PORT", 63106).to_i

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
    server = TCPServer.new @host, PORT
    puts "Listening on #{@host}:#{PORT}"
    Enviroblyd::Web.register

    loop do
      Thread.start(server.accept) do |client|
        command = Enviroblyd::Command.new client.recv(MAX_MESSAGE_SIZE)

        unless command.valid?
          client.puts "Invalid message"
          next
        end

        client.puts "OK"
        client.close
        command.run
      ensure
        client.close
        command = nil
        GC.start
      end
    end
  end
end
