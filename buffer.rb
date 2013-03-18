require "thread"

class Buffer
  attr_reader :current, :size, :id

  def initialize(size, id)
    @id      = id
    @size    = size
    @reserved = 0
    @queue =  Queue.new
  end

  def add(*items)
    unless has_space_for?(items.length)
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

  def has_space_for?(amount, options = {})
    reserved = options[:include_reserved] ? @reserved : 0
    @queue.size + amount + reserved <= @size
  end

  def can_take_items?(amount, options = {})
    reserved = options[:include_reserved] ? @reserved : 0
    @queue.size - amount - reserved >= 0
  end

  #
  # @return Array<Item>
  #
  def items
    @queue.instance_eval{ @que }
  end

  def average_time
    if total_time = (items.map(&:production_time).inject(:+) || 0) == 0 or tems.length.zero?
      raise "No items were produced"
    end

    (total_time / items.length.to_f).to_i
  end

  def current_size
    @queue.size
  end

  def empty?
    @queue.empty?
  end

  def full_including_reserved?
    @queue.size + @reserved == size
  end

  def unreserve(amount = 1)
    if @reserved.zero?
      raise ArgumentError.new("Nothing in buffer has been reserved")
    end

    @reserved -= amount
  end

  def reserve(amount = 1)
    if full_including_reserved?
      raise ArgumentError.new("Buffer is already full, including reserved items")
    end
    
    @reserved += amount
  end

  def to_s
    "<Buffer id: #{@id}, current_size: #{current_size}, size: #{@size}>"
  end

  def inspect
    to_s
  end
end
