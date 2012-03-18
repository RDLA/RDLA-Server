#encoding: utf-8
puts 'Starting server...'
puts 'Load library...'
#----------------------------------------------------- 
#                  INCLUDE
#-----------------------------------------------------
require 'em-websocket'        
require 'active_record'
require 'yaml'
require 'logger'


#Business Include
Dir["model/*.rb"].each {|file| require_relative file }
#----------------------------------------------------- 
#                  END INCLUDE
#-----------------------------------------------------

puts 'Load configuration...'
#----------------------------------------------------- 
#                  CONFIG
#-----------------------------------------------------
config = YAML::load(IO.read('config/global.yml'))
#----------------------------------------------------- 
#                  END CONFIG
#-----------------------------------------------------

#----------------------------------------------------- 
#                  DATABASE
#-----------------------------------------------------
puts 'Connect to Database...'
# Database connect
db_config = YAML::load(IO.read('config/database.yml'))
ActiveRecord::Base.establish_connection(db_config[config['env']])
ActiveRecord::Base.logger = Logger.new(STDOUT)
puts 'Calling migration'
#ActiveRecord::Migrator.migrate("migrations/")

#----------------------------------------------------- 
#                  END DATABASE
#-----------------------------------------------------

#----------------------------------------------------- 
#                  GLOBAL VARIABLE
#-----------------------------------------------------
players_connected = []; # List of all players connected to gameserver
#----------------------------------------------------- 
#                  GLOBAL VARIABLE
#-----------------------------------------------------


#----------------------------------------------------- 
#                  COMMAND
#-----------------------------------------------------
def broadcast_message(sender, msg, players_connected)
	players_connected.each do |player|

		player.websocket.send "[#{sender.name}]|#{msg}"
	end
end
def find_player_by_ws(ws, players_connected)
	player_result = nil
	players_connected.each do |player|
		if player.websocket == ws
			player_result = player
			break
		end
	end
	player_result
end
def find_player_by_posx_posy(x, y,players_connected)
	player_result = nil
	players_connected.each do |player|
		if player.posx == x && player.posy == y
			player_result = player
			break
		end
	end
	player_result
end
def broadcast_player_info_old(players_connected)
	players_connected.each do |player|
        list_player = player.map.get_players(player.posx,player.posy)
		list_player_sent = Array.new
		((player.posy-player.visual_acuity)..(player.posy+player.visual_acuity)).each do |y|
			line = nil
			((player.posx-player.visual_acuity)..(player.posx+player.visual_acuity)).each do |x|
				line = Array.new if line.blank?
				line << (list_player["#{x};#{y}"].blank? ? 0 : list_player["#{x};#{y}"].id)
				
			end
			list_player_sent << line
			line = nil
		
		end
			player.websocket.send "/LIST_PLAYER #{list_player_sent.to_json}"
			
		end unless players_connected.blank?
end
def broadcast_player_info(players_connected)
	players_connected.each do |player|
		list_player_sent = Array.new
		((player.posy-player.visual_acuity)..(player.posy+player.visual_acuity)).each do |y|
			line = nil
			((player.posx-player.visual_acuity)..(player.posx+player.visual_acuity)).each do |x|
				line = Array.new if line.blank?
				opponent = find_player_by_posx_posy(x,y,players_connected)
				line << (opponent.blank? ? 0 : opponent.id)
				
			end
			list_player_sent << line
			line = nil
		
		end
			player.websocket.send "/LIST_PLAYER #{list_player_sent.to_json}"
	end
end
#----------------------------------------------------- 
#                  END COMMAND
#-----------------------------------------------------

puts 'Waiting for client...'
#----------------------------------------------------- 
#                  EVENT MACHINE
#-----------------------------------------------------
  EventMachine.run do
 
#----------------------------------------------------- 
#                  SEND INFORMATION TO ALL PLAYER CONNECTED
#-----------------------------------------------------

	
 EventMachine::WebSocket.start(:host => config['host'], :port => config['port']) do |ws|
#----------------------------------------------------- 
#                  WEBSOCKET CONNECTION
#-----------------------------------------------------
      ws.onopen do
        
		puts 'User connected'
        ws.send "WAIT_AUTH"
		
      end
#----------------------------------------------------- 
#                  WEBSOCKET COMMAND
#-----------------------------------------------------
      ws.onmessage do |msg|
         if msg[0,11] == "/LOG player"
		  begin
			player = Player.find(msg[12..msg.length].to_i)
		  rescue
			player = nil
			ws.send "PLAYER_NOT_FOUND"
		  end
          unless player.blank?
		    player.websocket = ws
			
			if players_connected.include?(player)
				ws.send "ERR_ALREADY_LOGGED"
				ws.close_connection
			else
				players_connected << player
				puts "#{player.name} connected"
				ws.send "/INFO_PLAYER #{player.to_json}"
				
			end
            
          end       
		 elsif msg[0,5] == "/DOWN"
			p = find_player_by_ws(ws,players_connected);
			p.posy = p.posy+1
			broadcast_player_info(players_connected)
		 elsif msg[0,3] == "/UP"
		 	p = find_player_by_ws(ws,players_connected);
			p.posy = p.posy-1
			broadcast_player_info(players_connected)
		 elsif msg[0,6] == "/RIGHT"
		 	p = find_player_by_ws(ws,players_connected);
			p.posx = p.posx+1
			broadcast_player_info(players_connected)
		 elsif msg[0,5] == "/LEFT"
		 	p = find_player_by_ws(ws,players_connected);
			p.posx = p.posx-1
			broadcast_player_info(players_connected)
		 else
			sender = find_player_by_ws(ws, players_connected)
			broadcast_message(sender,msg,players_connected)
		 end
      end
#----------------------------------------------------- 
#                  WEBSOCKET DISCONNECTION
#-----------------------------------------------------
      ws.onclose do
        puts 'User disconnected'
		players_connected.each do |p|
          if p.websocket == ws
            players_connected.delete p

         end
        end
        
      end
    end
#----------------------------------------------------- 
#                  END WEBSOCKET
#-----------------------------------------------------
end
