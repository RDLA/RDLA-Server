#ruby start_bots.rb > /dev/null &
require_relative "Websocket.rb"

ws = WebSocket.new("ws://home.rdla.fr:8081")
is_connected = false
step = 0

while true
message = (ws.receive)[0]
  if message == "/WAIT_AUTH"
    puts "Waiting log"
    ws.send("/LOG player 6")
  elsif message[0..11] == "/YOUR_PLAYER"
    is_connected = true
    ws.send("Bouyah! Vous allez tous mourir!")
  else 
    puts "Unrecognised message: #{message}"
  end
  
  
  if is_connected
    direction = ["/LEFT","/UP","/RIGHT","/DOWN"]
    choice = direction[step]
    step = (step + 1) % direction.length
    ws.send(choice)
    puts "Go to #{choice}"
  end
  
  
  sleep(1)


end
