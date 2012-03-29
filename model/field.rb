require "RMagick"
require 'net/ftp'
class Field < ActiveResource::Base
  self.site = CONFIG["db_url"]

  # Internal: Get all field and create a picture containing all the
  # file stored in database, ordered by id.
  #
  # Returns true if the generation success, false otherwise.def self.generate_sprites
  def self.generate_sprites
    list = Magick::ImageList.new
    self.all.each do |field|
      list.read "#{CONFIG['assets_url']}#{field.filename}"
    end
    image = list.append(false)
    ftp=Net::FTP.new
    ftp.connect(CONFIG['ftp_url'],21)
    ftp.login(ENV['FTP_USER'],ENV['FTP_PASSWORD'])
    ftp.chdir("assets")
    image.write "#{ROOT_PATH}/tmp/field.png"
    ftp.putbinaryfile("#{ROOT_PATH}/tmp/field.png", "field.png")
    ftp.close
    true
  end
end
