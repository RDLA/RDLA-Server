class Server
   @@log = nil
   attr_accessor :config, :db_config, :maps
  
  def initialize()
    puts "Load configuration file..."
    load_config

    puts "Set log information..."
    set_log

    @@log.info("Try to connect to database...")
    connect_database
    @@log.info("Connected to database.")
    
    @@log.info("Load map...")
    preload_maps
    @@log.info("Map loaded.")
    
  end
  
  
  def run
    @@log.info("Server starting...")
    EventMachine.run do
 
    EventMachine.add_periodic_timer(@config["saving_timer"].to_i) do
      @@log.debug 'Save Information to database'
      t = Thread.new {
        Player.save_all
      }
      t.priority = -1
    end
    EventMachine::WebSocket.start(:host => config['host'], :port => config['port'], :debug => config['debug']) do |ws|
      ws.onopen do
        @@log.info 'User connected'
        ws.send "/WAIT_AUTH"
      end
      
      ws.onmessage do |cmd|
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


  def load_config
    begin
      @config = YAML::load(IO.read('config/global.yml'))
      @db_config = YAML::load(IO.read('config/database.yml'))
    rescue
      puts $!
      exit
    end
  end
  
  def set_log
    if @config["env"] == "development"
      @@log = Logger.new(STDOUT)
      @@log.level = Logger::DEBUG
    else
      @@log = Logger.new("#{config["env"]}.log")
      @@log.level = Logger::WARN
    end
  end
  def self.log
    @@log
  end
  

  
  def connect_database
    begin
    ActiveRecord::Base.establish_connection(@db_config[@config['env']])
    ActiveRecord::Base.logger = @@log
    rescue
      @@log.fatal("Error when connecting to database: #{$!}")
    end
  end
  
  def preload_maps
    
    Map.preload
    
  end

end
