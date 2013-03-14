require "thread"

class Buffer
  attr_reader :current, :size, :id

  def initialize(size, id)
    @id      = id
    @size    = size
    @reserve = 0
    @queue =  Queue.new
  end

  def add(*items)
    unless has_space_for?(items)
      raise ArgumentError.new("Can't increment full buffer #{id} #{current_size} : #{@size}")
    end

    items.flatten.each {|i| @queue.push(i) }
  end

  def take(amount = 1)
    unless can_take_items?(amount)
      raise ArgumentError.new("Can't increment full buffer #{id}")
    end

    amount.times.map { @queue.pop(true) }
  end

  def increment!(amount = 1)
    raise ArgumentError.new("#increment! is not in use, RTFM")
  end

  def decrement!(amount = 1)
    raise ArgumentError.new("#decrement! is not in use, RTFM")
  end

  def has_space_for?(items)
    @queue.size + items.length <= @size
  end

  def can_take_items?(amount)
    @queue.size - amount >= 0
  end

  def current_size
    @queue.size
  end

  def empty?
    @queue.empty?
  end

  def full_including_reserved?
    @queue.size + @reserve == size
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
    "<Buffer id: #{@id}, current_size: #{current_size}, size: #{@size}>"
  end

  def inspect
    to_s
  end
end
