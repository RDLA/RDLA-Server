class Field < ActiveRecord::Base
  has_many :maps  
  validates :color, :presence => true
end