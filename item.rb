class Item
  attr_reader :created_at
  attr_accessor :done_at
  
  def initialize
    @created_at = Time.now
  end

  #
  # @return Integer Time since creation in seconds
  #
  def production_time
    if done?
      raise RuntimeError.new("Item is not yet done")
    end

    if created_at > done_at
      raise RuntimeError.new("Item can't be done before its created")
    end

    return done_at.to_i - created_at.to_i
  end

  def done?
    !! done_at
  end
end