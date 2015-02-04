class ColorComponent
  attr_accessor :color, :type
  def initialize(color)
    @color = color
    @type = :color
  end
end

class PositionComponent
  attr_accessor :x, :y, :type
  def initialize(x,y)
    @type = :position
    @x = x
    @y = y
  end
end

class ControlComponent
  attr_accessor :move_right, :move_left, :move_up, :move_down, :type
  def initialize
    @type = :control
  end
end

class KeyboardControlComponent
  attr_accessor :move_right, :move_left, :move_up, :move_down, :type

  def initialize(opts={})
    @type = :keyboard_control
    @move_right, @move_left, @move_up, @move_down = opts.values_at(:move_right, :move_left, :move_up, :move_down)
  end
end

class SpeedComponent
  attr_accessor :speed, :type
  def initialize(speed)
    @type = :speed
    @speed = speed
  end
end

class ScaleComponent
  attr_accessor :scale, :type, :full_size
  def initialize(scale)
    @type = :scale
    @scale = scale
    @full_size = scale
  end
end

class TimerComponent
  attr_accessor :ttl, :repeat, :total, :event, :type, :name
  def initialize(name, ttl, repeat, event = nil)
    @type = :timer
    @name = name
    @total = ttl
    @ttl = ttl
    @repeat = repeat
    @event = event
  end
end

class BeepEvent
  attr_accessor :type
  def initialize
    @type = :beep
  end
end

