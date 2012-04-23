#encoding: utf-8
$stdout.sync = true
puts "Please wait while loading library..."
#----------------------------------------------------- 
#                  INCLUDE
#-----------------------------------------------------
require 'em-websocket'        
require 'active_resource'
require 'yaml'
require 'logger'
#----------------------------------------------------- 
#                  END INCLUDE
#-----------------------------------------------------
ROOT_PATH = File.dirname(File.expand_path(__FILE__));
puts ROOT_PATH
 puts "Load configuration file..."
begin
  config_file = YAML::load(File.open("#{ROOT_PATH}/config/global.yml"))
  CONFIG_ENV = ARGV[0] || "development"
  puts "Environnement: #{CONFIG_ENV}"
  CONFIG = config_file[CONFIG_ENV]
  CONFIG["env"] = CONFIG_ENV
rescue
  puts $!
  exit
end

puts "Please wait while loading network component..."
Dir["#{ROOT_PATH}/network/*.rb"].each {|file| require file }
puts "Please wait while loading business object component..."
Dir["#{ROOT_PATH}/model/*.rb"].each {|file| require file }

server = Server.new

server.run
