class Field < ActiveResource::Base
  self.site = CONFIG["db_url"]
  
end
