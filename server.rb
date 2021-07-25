# frozen_string_literal: true

require 'bundler/setup'
require 'tipi'

require_relative 'ws_handler'

puts "pid: #{Process.pid}"
puts 'Listening on port 4411...'

ws = WSHandler.new

opts = {
  reuse_addr: true,
  dont_linger: true,
  upgrade: {
    websocket: Tipi::Websocket.handler { ws.handler(_1) }
  }
}

app = Tipi.route do |r|
  r.on_root do
    html = IO.read(File.join(__dir__, 'index.html'))
    r.respond(html, 'Content-Type' => 'text/html')
  end

  r.on 'settings' do
    r.on_get do
      r.respond 'Settings Page to be added'
    end
  end
end

spin do
  Tipi.serve('0.0.0.0', 4411, opts, &app)
end.await
