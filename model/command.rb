#encoding: utf-8
class Command
  attr_accessor :cmd, :ws
  def initialize(cmd,ws)
    @cmd = cmd
    @ws = ws
  end
  def run
    sender = Player.online_find(@ws)
    if !sender.blank?
      if @cmd[0] != "/"
          #It is not a command: Send a message to all connected player     
          Player.broadcast "[#{sender.name}]: #{@cmd}" if !sender.blank?
      elsif ["/LEFT","/RIGHT","/DOWN","/UP"].include?(@cmd)
            #Player want to move.
            sender.move(@cmd)
            #Player.refresh
            Player.online.each do |id,player|
            	if player != sender
            		player.websocket.send "/MOVE #{@cmd.delete('/')} #{sender.id}"
            		player.websocket.send"/LIST_PLAYERS #{player.get_players.to_json}"
            	else
            		player.websocket.send"/LIST_PLAYERS #{player.get_players.to_json}"
             		player.websocket.send"/LIST_FIELDS #{player.get_fields.to_json}"  
            	end
            	
            end
            

      elsif @cmd == "/LIST"
            Player.refresh
      elsif @cmd[0,12] == "/INFO player"
      		p = Player.online_find(@cmd[13..@cmd.length].to_i)
      		if(p.blank?)
      			ws.send "/ERR_PLAYER_NOT_FOUND"
      		else
		  		response = {:id => p.id, :name => p.name}.to_json
		  		ws.send "/INFO_PLAYER #{response}"
      		end
      		
      end
    elsif @cmd[0,11] == "/LOG player" 
          #Looking for player
          response = Player.login(@cmd[12..@cmd.length].to_i, @ws)
          ws.send response

          if response == "/ERR_ALREADY_LOGGED"
         
            @ws.close_connection 
          else
          	
            Player.refresh
          
        	end
    end
    
  end  
end