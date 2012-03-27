class Map < ActiveResource::Base
  self.site = CONFIG["db_url"]
  @@list = {}
  @@list_id = {}
  

  attr_accessor :name, :posx_min, :posx_max, :posy_min, :posy_max,:fields
 
 
  
  
 
  
  def get_terraform(centrex, centrey, visual_acuity)
    fields_sent = Array.new
    
    (centrey-visual_acuity..centrey+visual_acuity).each do |y|
      line = nil
      (centrex-visual_acuity..centrex+visual_acuity).each do |x|
        line = Array.new if line.blank?
        if !self.fields["#{x}/#{y}"].blank?
        	line << self.fields["#{x}/#{y}"].to_i
        else
        	line << self.default_field_id
        end
      end
      fields_sent << line
      line = nil
    end 
    fields_sent
  end
  
  def self.list
    @@list
  end
  def self.preload
    #TODO: To test : 12.1.2 Nested Associations Hash in ruby on rails guide
    @@list = Map.all
    @@list.each do |map|
      @@list_id[map.id] = map
      
      map.fields = {}
      map.terraformings = Terraforming.all(:params => {:map_id => map.id })
      map.terraformings.each do |t|
     		
      	map.fields["#{t.posx}/#{t.posy}"] = t.field_id
      
      end
    end
  end
  def self.online_find(map_id)
    @@list_id[map_id]
  end
  
  
end
