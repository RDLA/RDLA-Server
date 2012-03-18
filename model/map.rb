class Map < ActiveRecord::Base
  @@list = {}
  @@list_id = {}
  
  attr_accessible :name
  attr_accessor :posx_min, :posx_max, :posy_min, :posy_max,:fields
  validates :name, :presence => true, :uniqueness => true
  has_many :terraformings
  
  belongs_to :default_field, :class_name => 'Field'
  validates :default_field, :presence => true
  
  def get_terraform(centrex, centrey, visual_acuity)
    fields_sent = Array.new
    
    (centrey-visual_acuity..centrey+visual_acuity).each do |y|
      line = nil
      (centrex-visual_acuity..centrex+visual_acuity).each do |x|
        line = Array.new if line.blank?
        if !self.fields["#{x}/#{y}"].blank?
        	line << self.fields["#{x}/#{y}"].to_i
        else
        	line << self.default_field.id
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
    @@list = Map.includes(:default_field,:terraformings => [:field]).all
    @@list.each do |map|
      @@list_id[map.id] = map
      map.posx_min = [ Terraforming.minimum(:posx, :conditions => ["map_id = ?", map.id]), -5 ].min
      map.posx_max = [ Terraforming.maximum(:posx, :conditions => ["map_id = ?", map.id]), 5 ].max
      map.posy_min = [ Terraforming.minimum(:posy, :conditions => ["map_id = ?", map.id]), -5 ].min
      map.posy_max = [ Terraforming.maximum(:posy, :conditions => ["map_id = ?", map.id]), 5 ].max
      map.fields = {}
      map.terraformings.each do |t|
     		
      	map.fields["#{t.posx}/#{t.posy}"] = t.field.id
      
      end
    end
  end
  def self.online_find(map_id)
    @@list_id[map_id]
  end
  
  
end
