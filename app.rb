require 'gosu'
require 'awesome_print'
require 'set'
require 'pry'

# NOTE:
# control component for this player vs AI player? tags?
# animations?
# control other dot with different keys
# collisions: http://forums.xkcd.com/viewtopic.php?f=11&t=81459
# ent A hurts ent B:
#   http://gamedev.stackexchange.com/questions/1119/entity-communication-message-queue-vs-publish-subscribe-vs-signal-slots
# hook up to sim-sim

class EntityManager
  attr_reader :component_store

  def create
    # TODO will probably need an Entity class for convenience
    @count += 1
    "E:#{@count}"
  end

  def initialize
    @count = 0
    @component_store = Hash.new{|h, k| h[k] = Hash.new{|hh, kk| hh[kk] = Set.new}}
    @events = {}
  end

  def emit_event(event, opts={})
    target_entity = opts[:on]
    @events[target_entity] ||= []
    @events[target_entity] << event

    add_component(event, to: target_entity)
  end

  def clear_events
    @events.each do |entity, events|
      events.each do |event|
        remove_component(event, from: entity)
      end
    end
    @events.clear
  end

  def entities_with_all_components(*components, &block)
    raise "No block give" unless block_given?

    first_component_ids = @component_store[components.first].keys
    ent_ids = components.inject(first_component_ids) do |comp_ids, comp|
      comp_ids &= @component_store[comp].keys
    end

    ent_ids.each do |ent_id|
      yield *components.map{|comp| @component_store[comp][ent_id]}, ent_id
    end
  end

  def add_component(component, opts={})
    target_entity = opts[:to]
    @component_store[component.class][target_entity] = component
    self
  end

  def remove_component(component, opts={})
    target_entity = opts[:from]
    @component_store[component.class].delete(target_entity)
    self
  end

  def remove_entity(entity)
    @component_store[component.class].delete(target_entity)
    self
  end
end

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

class BeepEvent
end

class BeepingSystem
  def initialize(window)
    # @beep = Gosu::Sample.new(window, 'beep.wav')
  end

  def update(entity_manager, dt, input)
    entity_manager.entities_with_all_components BeepEvent do |beep, ent_id|
      # puts "BEEP: #{ent_id}"
      # @beep.play
    end
  end
end

class ColorShiftSystem
  def update(entity_manager, dt, input)
    entity_manager.entities_with_all_components TimerComponent, ColorComponent do |timer, color, ent_id|
      c = color.color
      color.color = Gosu::Color.rgba(c.red, c.green, c.blue, 255 * (timer.ttl / timer.total))
    end
  end
end

class MovementSystem
  def update(entity_manager, dt, input)
    entity_manager.entities_with_all_components PositionComponent, ControlComponent, SpeedComponent do |pos, control, speed, ent_id|
      pos.x += dt*speed.speed if control.move_right
      pos.x -= dt*speed.speed if control.move_left
    end
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

class TimerSystem
  def update(entity_manager, dt, input)
    entity_manager.entities_with_all_components TimerComponent do |timer, ent_id|
      timer.ttl -= dt
      if timer.ttl < 0
        entity_manager.emit_event timer.event, on: ent_id unless timer.event.nil?
        if timer.repeat
          timer.ttl = timer.total
        else
          entity_manager.remove_component(timer, from: ent_id)
        end
      end
    end
  end
end

class InputMappingSystem
  def update(entity_manager, dt, input)
    exit if input.down?(Gosu::KbEscape)
    entity_manager.entities_with_all_components KeyboardControlComponent, ControlComponent do |keys, control, ent_id|
      control.move_left = input.down?(keys.move_left)
      control.move_right = input.down?(keys.move_right)
    end
  end
end

class RenderSystem
  def draw(target, entity_manager)
    entity_manager.entities_with_all_components PositionComponent, ColorComponent do |pos, color, ent_id|
      # puts "RENDER[#{ent_id}]: [#{pos.x},#{pos.y}] with color: #{color.color}"

      c1 = c2 = c3 = c4 = color.color
      x1 = pos.x
      y1 = pos.y
      x2 = x1+4
      y2 = y1
      x3 = x2
      y3 = y2+4
      x4 = x3-4
      y4 = y3
      target.draw_quad(x1, y1, c1, x2, y2, c2, x3, y3, c3, x4, y4, c4)
    end
  end
end


class MyGame < Gosu::Window
  MAX_UPDATE_SIZE_IN_MILLIS = 500
  def initialize
    super(300,300,false)

    @entity_manager = EntityManager.new 
    # maybe take a map to configure keys to component#fields
    @input_cacher = InputCacher.new
    # @style_applier.define_style(:ball) do
    #   position x: 9, y: 12
    #   color RED
    # end

    dot = @entity_manager.create
    @entity_manager.add_component KeyboardControlComponent.new(
                                    move_right: Gosu::KbRight, 
                                    move_left: Gosu::KbLeft), to: dot
    @entity_manager.add_component ControlComponent.new, to: dot
    @entity_manager.add_component SpeedComponent.new(0.1), to: dot
    @entity_manager.add_component PositionComponent.new(1,2), to: dot
    @entity_manager.add_component ColorComponent.new(Gosu::Color::RED), to: dot
    @entity_manager.add_component TimerComponent.new(1_000, true, BeepEvent.new), to: dot

    500.times do
      dot2 = @entity_manager.create
      @entity_manager.add_component KeyboardControlComponent.new(
                                      move_right: Gosu::KbD, 
                                      move_left: Gosu::KbA), to: dot2
      @entity_manager.add_component ControlComponent.new, to: dot2
      @entity_manager.add_component SpeedComponent.new(rand), to: dot2
      @entity_manager.add_component PositionComponent.new(rand(0..300),rand(0..200)), to: dot2
      @entity_manager.add_component ColorComponent.new(Gosu::Color::RED), to: dot2
      @entity_manager.add_component TimerComponent.new(rand(200..2000), true, BeepEvent.new), to: dot2
    end

    @input_mapping_system = InputMappingSystem.new
    @timer_system = TimerSystem.new
    @beeping_system = BeepingSystem.new(self)
    @movement_system = MovementSystem.new
    @color_shift_system = ColorShiftSystem.new
    @render_system = RenderSystem.new
    @update_systems = [
      @input_mapping_system,
      @timer_system,
      @beeping_system,
      @movement_system,
      @color_shift_system,
    ]
    @draw_systems = [ @render_system ]
  end

  def update
    self.caption = Gosu.fps

    millis = Gosu::milliseconds.to_f

    # ignore the first update
    if @last_millis
      delta = millis
      delta -= @last_millis if millis > @last_millis
      delta = MAX_UPDATE_SIZE_IN_MILLIS if delta > MAX_UPDATE_SIZE_IN_MILLIS

      input_snapshot = @input_cacher.snapshot
      @update_systems.each { |sys| sys.update(@entity_manager, delta, input_snapshot) }

      @entity_manager.clear_events
    end

    @last_millis = millis
  end

  def draw
    @draw_systems.each { |sys| sys.draw(self, @entity_manager) }
  end

  def button_down(id)
    if id == Gosu::KbP
      ap @entity_manager.component_store
    end
    @input_cacher.button_down id
  end

  def button_up(id)
    @input_cacher.button_up id
  end

end

class InputCacher
  attr_reader :down_ids

  def initialize(down_ids = nil)
    @down_ids = down_ids || Set.new
  end

  def button_down(id)
    @down_ids.add id
  end

  def button_up(id)
    @down_ids.delete id
  end

  def down?(id)
    @down_ids.include? id
  end

  def snapshot
    InputCacher.new(@down_ids.dup)
  end
end


MyGame.new.show
