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


