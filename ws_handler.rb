# frozen_string_literal: true

require 'tipi'
require 'tipi/websocket'

require_relative 'timer_clock'

class WSHandler
  def initialize
    @clients = []
    spin do
      @timer = Timer::Clock.new(strategy: 'elapsed', rotation: 1000, climbing: 1000, start_at: nil)
      @timer.run { broadcast }
    end
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

  def broadcast
    @clients.each.with_index do |c, i|
      c << diagnostics.call(@timer)
      # Print diagnostic data
      open("conn_#{i}", 'a') { _1.puts diagnostics.call(@timer) }
    end
  end

  def diagnostics
    ->(t) { "#{t.strtime}, #{'%.5f' % t.seconds}, #{Process.clock_gettime(Process::CLOCK_MONOTONIC)}" }
  end
end
