#encoding: utf-8

puts "Please wait while loading library..."
#----------------------------------------------------- 
#                  INCLUDE
#-----------------------------------------------------
require 'em-websocket'        
require 'active_record'
require 'yaml'
require 'logger'
#----------------------------------------------------- 
#                  END INCLUDE
#-----------------------------------------------------
puts "Please wait while loading network component..."
Dir["network/*.rb"].each {|file| require_relative file }
puts "Please wait while loading business object component..."
Dir["model/*.rb"].each {|file| require_relative file }




server = Server.new

server.run
