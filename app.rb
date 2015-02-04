require 'gosu'
require 'awesome_print'
require 'set'
require 'pry'

require_relative 'components'
require_relative 'systems'
require_relative 'entity_manager'
require_relative 'input_cacher'

# NOTE: TODO
# add timer to dot for scale
# delay add/remove of ents and comps until end of 'tick'
# query based on key/value pairs instead of component types
# control component for this player vs AI player? tags?
# animations?
# collisions: http://forums.xkcd.com/viewtopic.php?f=11&t=81459
# particle effects on death?
# ent A hurts ent B:
#   http://gamedev.stackexchange.com/questions/1119/entity-communication-message-queue-vs-publish-subscribe-vs-signal-slots
# game states?
# hook up to sim-sim


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
                                    move_up: Gosu::KbUp, 
                                    move_down: Gosu::KbDown, 
                                    move_right: Gosu::KbRight, 
                                    move_left: Gosu::KbLeft), to: dot
    @entity_manager.add_component ControlComponent.new, to: dot
    @entity_manager.add_component SpeedComponent.new(0.1), to: dot
    @entity_manager.add_component PositionComponent.new(1,2), to: dot
    @entity_manager.add_component ColorComponent.new(Gosu::Color::RED), to: dot
    @entity_manager.add_component ScaleComponent.new(5), to: dot

    @entity_manager.add_component TimerComponent.new(:color, 1_000, true), to: dot
    @entity_manager.add_component TimerComponent.new(:beeppp, 1_000, true, BeepEvent), to: dot
    @entity_manager.add_component TimerComponent.new(:scale, 1_000, true), to: dot

    dot2 = @entity_manager.create
    @entity_manager.add_component KeyboardControlComponent.new(
                                    move_up: Gosu::KbW, 
                                    move_down: Gosu::KbS, 
                                    move_right: Gosu::KbD, 
                                    move_left: Gosu::KbA), to: dot2
    @entity_manager.add_component ControlComponent.new, to: dot2
    @entity_manager.add_component SpeedComponent.new(0.1), to: dot2
    @entity_manager.add_component PositionComponent.new(100,2), to: dot2
    @entity_manager.add_component ColorComponent.new(Gosu::Color::RED), to: dot2
    @entity_manager.add_component ScaleComponent.new(5), to: dot2

    @entity_manager.add_component TimerComponent.new(:color, 1_000, true), to: dot2
    @entity_manager.add_component TimerComponent.new(:beeppp, 1_000, true, BeepEvent), to: dot2
    @entity_manager.add_component TimerComponent.new(:scale, 1_000, true), to: dot2

    # 500.times do
#     1.times do
#       dot2 = @entity_manager.create
#       @entity_manager.add_component KeyboardControlComponent.new(
#                                       move_up: Gosu::KbW, 
#                                       move_down: Gosu::KbS, 
#                                       move_right: Gosu::KbD, 
#                                       move_left: Gosu::KbA), to: dot2
#       @entity_manager.add_component ControlComponent.new, to: dot2
#       @entity_manager.add_component SpeedComponent.new(0.1), to: dot2
#       @entity_manager.add_component PositionComponent.new(1,2), to: dot2
#       @entity_manager.add_component ColorComponent.new(Gosu::Color::RED), to: dot2
#       @entity_manager.add_component ScaleComponent.new(5), to: dot2
#
#       @entity_manager.add_component TimerComponent.new(:color, 1_000, true), to: dot2
#       @entity_manager.add_component TimerComponent.new(:beeppp, 1_000, true, BeepEvent), to: dot2
#       @entity_manager.add_component TimerComponent.new(:scale, 3_000, true), to: dot2
#
#     end

    @input_mapping_system = InputMappingSystem.new
    @timer_system = TimerSystem.new
    @beeping_system = BeepingSystem.new(self)
    @movement_system = MovementSystem.new
    @color_shift_system = ColorShiftSystem.new
    @scale_system = ScaleSystem.new
    @render_system = RenderSystem.new
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
      @input_mapping_system.update @entity_manager, delta, input_snapshot
      @timer_system.update @entity_manager, delta, input_snapshot
      @beeping_system.update @entity_manager, delta, input_snapshot
      @movement_system.update @entity_manager, delta, input_snapshot
      @color_shift_system.update @entity_manager, delta, input_snapshot
      @scale_system.update @entity_manager, delta, input_snapshot

      @entity_manager.clear_events
    end

    @last_millis = millis
  end

  def draw
    @render_system.draw self, @entity_manager
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

MyGame.new.show
