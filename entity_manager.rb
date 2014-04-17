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
