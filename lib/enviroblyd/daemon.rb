# frozen_string_literal: true

require "socket"

class Enviroblyd::Daemon
  MAX_MESSAGE_SIZE = 6000 # bytes
  LISTEN_PORT = ENV.fetch("ENVIROBLYD_PORT", 63106).to_i

  def self.start
    web = Enviroblyd::Web.new
    web.register

    daemon = new
    daemon.listen
  end

  def listen
    server = TCPServer.new LISTEN_PORT
    puts "Listening on port #{LISTEN_PORT}"

    loop do
      Thread.start(server.accept) do |client|
        message = client.recv(MAX_MESSAGE_SIZE)

        puts "Received:"
        puts message

        # if message.bytesize > MAX_MESSAGE_SIZE
        #   client.puts "Error: Message too large."
        # else
        #   client.puts "#{Time.now} #{message}"
        # end

        # TODO: Handle Broken pipe (Errno::EPIPE) (client closing connection before we write back)

        client.puts "OK"
        client.close
      end
    end
  end
end
