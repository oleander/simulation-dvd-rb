require "./production"

class Fruit < Production
  def init
    @buffer_capacity = 1000
    @buffer = 0
    @time_buffer_empty = 0
    schedule(new_lifetime, "Machine 1 is now broken", :machine_1_broken, current_time)
    done_in(2.hours) do
      debug("Time buffer empty: #{@time_buffer_empty}")
    end
  end

  def machine_1_broken(started_at)
    time_passed = (current_time - started_at).to_i
    produced = 3 * time_passed
    reduced = - 2 * time_passed
    if produced - reduced + @buffer < @buffer_capacity
      @buffer +=  produced - reduced
      debug("New buffer value is #{@bufferCur}")
    else
      @buffer = @buffer_capacity
      debug("Buffer is full #{@bufferCur}")
    end

    schedule(new_lifetime, "Machine 1 is now fixed", :machine_1_fixed, current_time)
  end

  def machine_1_fixed(broken_at)
    @buffer = @buffer - 2 * (current_time - broken_at).to_i
    if @buffer < 0
      @time_buffer_empty += @buffer.abs
      @buffer = 0
    end

    debug("Buffer counter is not #{@buffer}")

    schedule(new_lifetime, "Machine 1 is now broken", :machine_1_broken, current_time)
  end

  def new_lifetime
    rand(100).seconds
  end
end

Fruit.new