class Terraforming < ActiveRecord::Base
  
  validates :map_id, :presence => true
  validates :field_id, :presence => true
  validates :posx, :presence => true
  validates :posy, :presence => true
  
  belongs_to :map
  belongs_to :field
end