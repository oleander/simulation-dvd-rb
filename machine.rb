class Machine
  def initialize(next_buffer, previous_buffer, items_per_second, id)
    @previous_buffer = previous_buffer
    @next_buffer = next_buffer

    @broken = false

    @id = id

    @items_per_second = items_per_second
  end

  def trigger!(time_difference)
    trigger_front(time_difference)
  end

  def trigger_back
    # There is too many items in buffers, adjust!
    if @next_buffer.overload?
      overload = @next_buffer.overload.abs
      @next_buffer.remove(overload)

      # If we don't have any buffers
      # then we don't have anything to adjust
      return unless has_previous_buffer?
      @previous_buffer.add(overload)
    end

    # Update machine before us
    @previous_machine.trigger_back
  end

  def reduce_all(reduce)
    @next_buffer.remove(reduce)
    reduce_all_right(reduce)
    reduce_all_left(reduce)
  end

  def reduce_all_right(reduce)
    if @next_machine
      @next_buffer.remove(reduce)
      @next_machine.reduce_all_right(reduce)
    end
  end

  def reduce_all_left(reduce)
    if @previous_machine
      @previous_buffer.remove(reduce)
      @previous_machine.reduce_all_left(reduce)
    end
  end

  def trigger_front(time_difference)
    # Do we've a previous batch to take items from?
    if has_previous_buffer?
      # Select min between
      # 1. Items in previous batch
      # 2. Amount we can produce during #time_difference
      items_to_add = [items_produces_during(time_difference), @previous_buffer.size].min

      # Update next buffer in line
      @next_buffer.add(items_to_add)
    else
      # Add items to buffer, even if it's full
      @next_buffer.add(items_produces_during(time_difference))
    end

    # Unless last machine in line
    if has_next_machine?
      # Trigger next machine
      @next_machine.trigger!(time_difference)
    else
      self.trigger_back
    end
  end

  def has_next_machine?
    !! @next_machine
  end
  #
  # @return Boolean Do we've a previous batch to take items from?
  #
  def has_previous_buffer?
    !! @previous_buffer
  end

  def start!
    if broken?
      raise "machine #{@id} is broken"
    end

    @started_at = current_time
  end

  def items_produces_during(time_difference)
    time_difference * @items_per_second
  end

  def broken?
    @broken
  end

  def started?
    !! @started_at
  end

  def up_since
    if broken?
      raise "machine #{@id} is still broken"
    end

    unless started?
      raise "machine #{@id} has never been started"
    end

    current_time - @started_at
  end

  def elapsed_time_since_breakdown
    unless broken?
      raise "machine #{@id} is not broken"
    end

    current_time - @broken_at
  end

  def current_time
    Time.now
  end

  def fixed!
    unless broken?
      raise "machine #{@id} is not broken, why fix it?"
    end

    @broken = false
    @started_at = current_time
  end

  def broken!
    if broken?
      raise "machine #{@id} is already broken"
    end

    @broken = true
    @broken_at = current_time
  end

  def next_machine=(machine)
    @next_machine = machine
  end

  def previous_machine=(machine)
    @previous_machine = machine
  end
end

class Buffer
  def initialize(max_size, id)
    @max_size = max_size
    @current_items = 0
    @id = id
  end

  #
  # @items Integer
  #
  def add(items)
    @current_items += items
  end

  #
  # @return Integer Amount of items in batch
  #
  def size
    @current_items
  end
  
  #
  # @return Integer How mutch extra does the buffer contain?
  #
  def overload
    @max_size - @current_items
  end

  #
  # @return Boolean Is this buffer overloaded?
  #
  def overload?
    overload < 0
  end

  def remove(items)
    @current_items -= items
  end

  def inspect
    "Maxsize: #{@max_size}, Current Size: #{@current_items}, ID: #{@id}"
  end
end

####
# Initialize machines and buffers
####
b1 = Buffer.new(100, 1)
b2 = Buffer.new(200, 2)
b3 = Buffer.new(500000, 3) # Last one

m1 = Machine.new(b1, nil, 5, 1)
m2 = Machine.new(b2, b1, 10, 2)
m3 = Machine.new(b3, b2, 15, 3)

m1.next_machine = m2

m2.next_machine = m3
m2.previous_machine = m1

m3.previous_machine = m2

####
# Execute updates
####
m1.trigger!(50)
puts b1.inspect
puts b2.inspect
puts b3.inspect