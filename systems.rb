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

