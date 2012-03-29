#encoding: utf-8
class Player < ActiveResource::Base
  self.site = CONFIG["db_url"]
  @@online_player = {}
  @@online_ws = {}
  @@online_map = {}
  attr_accessor :websocket 
  
  def get_fields()
    Map.online_find(self.map_id).get_terraform(posx,posy,visual_acuity+1)
  end
  
  def get_players()
    list_player_sent = Array.new
    ((posy-visual_acuity-1)..(posy+visual_acuity+1)).each do |y|
      line = nil
      ((posx-visual_acuity-1)..(posx+visual_acuity+1)).each do |x|
        line = Array.new if line.blank?
        opponent = Player.online_find("#{x}/#{y}/#{map_id}")
        line << (opponent.blank? ? 0 : opponent.id)
      end
      list_player_sent << line
      line = nil
    
    end
    list_player_sent
  end
  
  
  
  def move(direction)
      if(self.available?(direction))
		  @@online_map.delete "#{self.posx}/#{self.posy}/#{self.map_id}"
		  self.posx -= 1 if direction == "/LEFT"
		  self.posx += 1 if direction == "/RIGHT"
		  self.posy -= 1 if direction == "/UP"
		  self.posy += 1 if direction == "/DOWN"
		  @@online_map["#{self.posx}/#{self.posy}/#{self.map_id}"] = self
     end
  end
  
  def available?( direction)
  		  cposx, cposy = self.posx, self.posy
  		  cposx = self.posx - 1 if direction == "/LEFT"
		  cposx = self.posx + 1 if direction == "/RIGHT"
		  cposy = self.posy - 1 if direction == "/UP"
		  cposy = self.posy+ 1 if direction == "/DOWN"
  		!@@online_map.include?("#{cposx}/#{cposy}/#{self.map_id}")
  end
   def find_available_position()
  		radius = 0
  		is_player = true
  		while is_player
	  		((self.posy-radius)..(self.posy+radius)).each do |y|
	  			((self.posx-radius)..(self.posx+radius)).each do |x|
	  				is_player = @@online_map.include?("#{x}/#{y}/#{self.map_id}")
	  				
	  				if !is_player
	  					
	  					self.posx = x
	  					self.posy = y
	  					return true
	  				end
	  			end
	  			
	  			end
	  			
	  			radius += 1
	  		
  		end
  		return false
  		
  end
 
#----------------------------------------------------- 
#                  CLASS METHOD
#-----------------------------------------------------
  def self.broadcast(msg)
      @@online_player.each do |id, player|
        
        player.websocket.send(msg)
      end
  end
  
  def self.online?(player)
  
  	if player.is_a?(Integer)
  	  @@online_player.include?(player)
    elsif player.is_a?(Player)
      @@online_player.include?(player.id)
    else #Websocket
      @@online_ws.include?(player)
    end
  end
  
  def self.online_find(player)
    if player.is_a?(Integer)
      @@online_player[player]
    elsif player.is_a?(EventMachine::WebSocket::Connection)
      @@online_ws[player] 
    else
       @@online_map[player]
    end
  end
  
  def self.online
    @@online_player
  end
  
  def self.connect(player)
    @@online_player[player.id] = player
    @@online_ws[player.websocket] = player
    player.find_available_position()
    @@online_map["#{player.posx}/#{player.posy}/#{player.map_id}"] = player
  end
  
 
  
  def self.disconnect(ws)
    player = Player.online_find(ws)
    unless player.blank?
    @@online_player.delete player.id
    @@online_ws.delete player.websocket
    @@online_map.delete "#{player.posx}/#{player.posy}/#{player.map_id}"
    Player.broadcast "#{player.name} vient de se déconnecter."
    player.save
    player
    end
  end
  
  def self.login(player_id, ws)
    begin
      player = Player.find(player_id)
    rescue
      player = nil
      response = "/ERR_PLAYER_NOT_FOUND"
    end
    
    unless player.blank?
   
      if Player.online?(player)
        response = "/ERR_ALREADY_LOGGED"
      else
      	player.websocket = ws
        Player.connect(player)
        Server.log.info "#{player.name}(ID:#{player.id}) connected"
        Player.broadcast "#{player.name} vient de se connecter."
        response = "/YOUR_PLAYER #{player.to_json}"
        Player.online.each do |id,player_i|
        	Player.send_player_info(player,player_i)
        	Player.send_player_info(player_i,player)
        end # Player.online.each
          	
      end # Player.online?
    
    end # player.blank?

    response
  end # self.login
  
  
  def self.send_player_info(player_info,recever)
  		info_sent = {:id => player_info.id, :name => player_info.name}.to_json
        recever.websocket.send "/INFO_PLAYER #{info_sent}"
  end
  
  def self.save_all
     Player.online.each do |id,player|
      player.save
    end
  end
  
  def self.refresh
    Player.online.each do |id,player|
              player.websocket.send "/LIST_PLAYERS #{player.get_players.to_json}"
              player.websocket.send "/LIST_FIELDS #{player.get_fields.to_json}"
                
            end
  end
  
    
end
