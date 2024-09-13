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
        message = client.recv(MAX_MESSAGE_SIZE)
        command = Enviroblyd::Command.new message

        unless command.valid?
          $stderr.puts "Invalid message received: #{message}"
          client.puts "Invalid message"
          next
        end

        client.puts "OK"
        client.close
        command.run
      ensure
        client.close
        command = nil
        message = nil
        client = nil
        GC.start
      end
    end
  end
end
