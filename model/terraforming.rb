class Terraforming < ActiveResource::Base
  self.site = "#{CONFIG["db_url"]}maps/:map_id/"
  

end
