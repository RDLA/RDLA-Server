class Server
   @@log = nil
  
   attr_accessor :maps
  
  def initialize()
   
    puts "Set log information..."
    set_log
    ActiveResource::Base.logger = @@log
    
     @@log.info("Load map...")
    preload_maps
    @@log.info("Map loaded.")
  end
  
  
  def run
  
  
    @@log.info("Server starting...")
   
    EventMachine.run do
 
    EventMachine.add_periodic_timer(CONFIG["saving_timer"].to_i) do
      @@log.debug 'Save Information to database'
      t = Thread.new {
        Player.save_all
      }
      t.priority = -1
    end
    EventMachine::WebSocket.start(:host => CONFIG['host'], :port => CONFIG['port'], :debug => CONFIG['debug']) do |ws|
      ws.onopen do
        @@log.info 'User connected'
        ws.send "/WAIT_AUTH"
      end
      
      ws.onmessage do |cmd|
        cmd = cmd.force_encoding('UTF-8') #Try to fix problem of crash.
        c = Command.new(cmd,ws)
        c.run
      end #ws.onmessage
      
      ws.onclose do
        player = Player.disconnect(ws)
        Player.refresh
        @@log.info "#{player.name} disconnected" rescue  @@log.info "User disconnected"   
      end
      
     end #EventMachine::Websocket
    end #EventMachine.run
  end #run



  
  def set_log
    if CONFIG["env"] == "development"
      @@log = Logger.new(STDOUT)
      @@log.level = Logger::DEBUG
    else
      @@log = Logger.new("#{CONFIG["env"]}.log")
      @@log.level = Logger::WARN
    end
  end
  def self.log
    @@log
  end
  

  

  
  def preload_maps
    
    Map.preload
    
  end

end
