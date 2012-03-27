#encoding:utf-8
class Dice
  attr_accessor :x, :y, :str, :result
  # Format : 5D12
  def initialize(dice_str)
    info = dice_str.downcase.split("d") 
    @x = info[0].to_i
    @y = info[1].to_i
    @str = "#{@x}D#{@y}"
  end
  
  def roll
    @result = 0  
    if @x.is_a?(Integer) && @y.is_a?(Integer) && @y > 0
      @x.times do
        @result += Random.rand(@y)+1
      end    
    end
    @result
  end

end
