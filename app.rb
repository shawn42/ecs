require 'gosu'
require 'set'
require 'pry'

# NOTE:
# pass input_cacher.snapshot down through system updates
# timer "callbacks"?
#   - since timers are SO simple, does it make sense to have:
#   ChangeColorEverySoOftenSystem? ColorChangingSystem
# control component for this player vs AI player? tags?
# some sort of "events"

class EntityManager
  def create
    # TODO will probably need an Entity class for convenience
    @count += 1
    "E:#{@count}"
  end

  def initialize
    @count = 0
    @component_store = Hash.new{|h, k| h[k] = Hash.new{|hh, kk| hh[kk] = Set.new}}
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

class MovementSystem
  def update(entity_manager, dt)
    entity_manager.entities_with_all_components PositionComponent, ControlComponent do |pos, control, ent_id|
      pos.x += dt/10 if control.move_right
      pos.x -= dt/10 if control.move_left
    end
  end
end

class TimerComponent
  attr_accessor :ttl, :loop
end

class TimerSystem
  def update(entity_manager, dt)
    entity_manager.entities_with_all_components TimerComponent do |timer, ent_id|
    end
  end
end

class InputMappingSystem
  def initialize(input_cacher)
    @input = input_cacher
  end

  def update(entity_manager, dt)
    exit if @input.down?(Gosu::KbEscape)
    entity_manager.entities_with_all_components ControlComponent do |control, ent_id|
      control.move_left = @input.down?(Gosu::KbLeft)
      control.move_right = @input.down?(Gosu::KbRight)
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


    entity = @entity_manager.create #:ball
    @entity_control = ControlComponent.new
    @entity_manager.add_component @entity_control, to: entity
    @entity_manager.add_component PositionComponent.new(1,2), to: entity
    @entity_manager.add_component ColorComponent.new(Gosu::Color::RED), to: entity
    @input_mapping_system = InputMappingSystem.new @input_cacher
    @movement_system = MovementSystem.new
    @render_system = RenderSystem.new
    @update_systems = [
      @input_mapping_system,
      @movement_system,
    ]
    @draw_systems = [ @render_system ]
  end

  def update
    millis = Gosu::milliseconds.to_f

    # ignore the first update
    if @last_millis
      delta = millis
      delta -= @last_millis if millis > @last_millis
      delta = MAX_UPDATE_SIZE_IN_MILLIS if delta > MAX_UPDATE_SIZE_IN_MILLIS

      # puts "update #{delta}"
    end

    @update_systems.each { |sys| sys.update(@entity_manager, delta) }

    @last_millis = millis
  end

  def draw
    @draw_systems.each { |sys| sys.draw(self, @entity_manager) }
  end

  def button_down(id)
    @input_cacher.button_down id
  end

  def button_up(id)
    @input_cacher.button_up id
  end

end

class InputCacher
  attr_reader :down_ids

  def initialize
    @down_ids = Set.new
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
end


MyGame.new.show
