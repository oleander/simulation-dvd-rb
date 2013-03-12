class Buffer
  attr_reader :current, :size, :id

  def initialize(size, id)
    @id      = id
    @size    = size
    @reserve = 0
    @current =  0
  end

  def increment!(amount = 1)
    if full?
      raise ArgumentError.new("Can't increment full buffer #{id}")
    end

    @current += amount
  end

  def decrement!(amount = 1)
    if empty?
      raise ArgumentError.new("Can't decrement empty buffer #{id}")
    end

    @current -= amount
  end

  #
  # @return Boolean Is buffer empty?
  #
  def empty?
    @current <= 0
  end

  #
  # @return Boolean Is buffer full?
  #
  def full?
    return @current >= @size
  end

  def full_including_reserved?
    @current + @reserve == size
  end

  def unreserve(amount = 1)
    if @reserve.zero?
      raise ArgumentError.new("Nothing in buffer has been reserved")
    end

    @reserve -= amount
  end

  def reserve(amount = 1)
    if full_including_reserved?
      raise ArgumentError.new("Buffer is already full, including reserved items")
    end
    
    @reserve += amount
  end

  def to_s
    "<Buffer id: #{@id}, current: #{@current}, size: #{@size}>"
  end

  def inspect
    to_s
  end
end
