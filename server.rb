# frozen_string_literal: true

require 'bundler/setup'
require 'tipi'
require 'tipi/websocket'

def countdown(conn)
  spin_loop(interval: 1) do
    t = Time.now
    conn << "#{format('%02d', t.min.remainder(4))}:#{format('%02d', t.sec)}:#{t.nsec}"
  end
end

def ws_handler(conn)
  puts 'handler called'
  timer = countdown(conn)

  while (msg = conn.recv)
    conn << "you said: #{msg}"
  end
rescue Exception => e
  p e
ensure
  timer.stop
end

opts = {
  reuse_addr: true,
  dont_linger: true,
  upgrade: { websocket: Tipi::Websocket.handler(&method(:ws_handler)) }
}

puts "pid: #{Process.pid}"
puts 'Listening on port 4411...'

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
