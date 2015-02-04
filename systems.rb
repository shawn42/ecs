class BeepingSystem
  def initialize(window)
    @beep = Gosu::Sample.new(window, 'beep.ogg')
  end

  def update(entity_manager, dt, input)
    entity_manager.query_entities :beep do |event, ent_id|
      # puts "BEEP: #{ent_id}"
      @beep.play
    end
  end
end

class ColorShiftSystem
  def update(entity_manager, dt, input)
    entity_manager.query_entities({type: :timer, name: :color}, :color) do |timer, color, ent_id|
      c = color.color
      color.color = Gosu::Color.rgba(c.red, c.green, c.blue, 255 * (timer.ttl / timer.total)) if timer
    end
  end
end

class ScaleSystem
  def update(entity_manager, dt, input)
    entity_manager.query_entities({type: :timer, name: :scale}, :scale) do |timer, scale, ent_id|
      scale.scale = (scale.full_size * (timer.ttl / timer.total))#.round
    end
  end
end

class MovementSystem
  def update(entity_manager, dt, input)
    entity_manager.query_entities :position, :control, :speed do |pos, control, speed, ent_id|
      pos.x += dt*speed.speed if control.move_right
      pos.x -= dt*speed.speed if control.move_left
      pos.y += dt*speed.speed if control.move_down
      pos.y -= dt*speed.speed if control.move_up
    end
  end
end

class TimerSystem
  def update(entity_manager, dt, input)
    entity_manager.query_entities :timer do |timer, ent_id|
      timer.ttl -= dt
      if timer.ttl <= 0
        entity_manager.emit_event timer.event.new, on: ent_id if timer.event
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
    entity_manager.query_entities :keyboard_control, :control do |keys, control, ent_id|
      control.move_left = input.down?(keys.move_left)
      control.move_right = input.down?(keys.move_right)
      control.move_up = input.down?(keys.move_up)
      control.move_down = input.down?(keys.move_down)
    end
  end
end

class RenderSystem
  def draw(target, entity_manager)
    entity_manager.query_entities :position, :color, :scale do |pos, color, scale, ent_id|
      # puts "RENDER[#{ent_id}]: [#{pos.x},#{pos.y}] with color: #{color.color} and scale: #{scale.scale}"

      c1 = c2 = c3 = c4 = color.color
      # c = color
      # c1 = c2 = c3 = c4 = Gosu::Color.rgba(c[:r],c[:g],c[:b],c[:a])
      x1 = pos.x
      y1 = pos.y
      x2 = x1+scale.scale
      y2 = y1
      x3 = x2
      y3 = y2+scale.scale
      x4 = x3-scale.scale
      y4 = y3
      target.draw_quad(x1, y1, c1, x2, y2, c2, x3, y3, c3, x4, y4, c4)
    end
  end
end

