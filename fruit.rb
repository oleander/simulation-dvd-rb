require "./production"

class Fruit < Production
  def setup
    @buffer_capacity = 1000
    @buffer = 0
    @time_buffer_empty = 0
    schedule(new_lifetime, "Machine 1 is now broken", :machine_1_broken, "hello")
    done_in(100.hours) do
      debug("Time was buffer empty: #{@time_buffer_empty}", :red)
    end
  end

  def machine_1_broken(hi, time_passed)
    produced = 3 * time_passed
    reduced = - 2 * time_passed
    if produced - reduced + @buffer < @buffer_capacity
      @buffer +=  produced - reduced
      debug("New buffer value is #{@bufferCur}")
    else
      @buffer = @buffer_capacity
      debug("Buffer is full #{@bufferCur}")
    end

    schedule(new_lifetime * 1.5, "Machine 1 is now fixed", :machine_1_fixed, hi)
  end

  def machine_1_fixed(hi, time_passed)
    @buffer = @buffer - 2 * time_passed
    if @buffer < 0
      @time_buffer_empty += @buffer.abs
      @buffer = 0
    end

    debug("Buffer counter is now #{@buffer}")

    schedule(new_lifetime, "Machine 1 is now broken", :machine_1_broken, hi)
  end

  def new_lifetime
    rand(100).seconds
  end
end

Fruit.new