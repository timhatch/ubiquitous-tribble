# frozen_string_literal: true

require 'tipi'
require 'tipi/websocket'

require_relative 'timer'

class WSHandler
  def initialize
    @clients = []
    @timer   = Timer.new(strategy: 'rotation', rotation: 75, climbing: 60, start_at: nil)
    broadcast_loop
  end

  def handler(conn)
    while (msg = conn.recv)
      if msg.eql?('timer')
        @clients << conn
      else
        p conn.recv
        @clients.delete(conn)
      end
    end
  # rubocop:disable Lint/RescueException
  rescue Exception => e
    p e
  end
  # rubocop:enable Lint/RescueException

  def broadcast_loop
    spin do
      @timer.run do
        @clients.each.with_index do |c, _i|
          c << diagnostics.call(@timer)
          # Print diagnostic data
          # open("conn_#{i}", 'a') { _1.puts diagnostics.call(@timer) }
        end
      end
    end
  end

  def diagnostics
    ->(t) { "#{t.strtime}, #{'%.5f' % t.seconds}, #{Process.clock_gettime(Process::CLOCK_MONOTONIC) % 1}" }
  end
end
