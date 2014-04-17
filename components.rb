class ColorComponent
  attr_accessor :color
  def initialize(color)
    @color = color
  end
end

class PositionComponent
  attr_accessor :x, :y
  def initialize(x,y)
    @x = x
    @y = y
  end
end

class ControlComponent
  attr_accessor :move_right
  attr_accessor :move_left
end

class KeyboardControlComponent
  attr_accessor :move_right
  attr_accessor :move_left

  def initialize(opts={})
    @move_right, @move_left = opts.values_at(:move_right, :move_left)
  end
end

class SpeedComponent
  attr_accessor :speed
  def initialize(speed)
    @speed = speed
  end
end

class TimerComponent
  attr_accessor :ttl, :repeat, :total, :event
  def initialize(ttl, repeat, event = nil)
    @total = ttl
    @ttl = ttl
    @repeat = repeat
    @event = event
  end
end


class BeepEvent
end

