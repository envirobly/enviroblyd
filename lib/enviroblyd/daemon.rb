# frozen_string_literal: true

require "socket"

class Enviroblyd::Daemon
  MAX_MESSAGE_SIZE = 6000 # bytes
  PORT = ENV.fetch("ENVIROBLYD_PORT", 63106).to_i

  def initialize
    imds = Enviroblyd::IMDS.new
    @host = imds.private_ipv4
    @threads = []
    @shutdown = false
  end

  def listen
    @server = TCPServer.new @host, PORT
    puts "Listening on #{@host}:#{PORT}"
    Enviroblyd::Web.register

    until @shutdown do
      @threads << Thread.start(@server.accept) do |client|
        message = client.recv(MAX_MESSAGE_SIZE)
        command = Enviroblyd::Command.new message

        unless command.valid?
          puts "Invalid message received: #{message}"
          client.puts "Invalid message"
          next
        end

        client.puts "OK"
        client.close
        command.run
      ensure
        client.close
      end

      delete_dead_threads
      GC.start
      GC.compact
    end
  end

  def shutdown
    @threads.each(&:join)
  end

  private
    def delete_dead_threads
      @threads.each do |thread|
        next if thread.alive?
        @threads.delete thread
      end
    end
end
