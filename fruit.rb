require "./production"

class Fruit < Production
  def setup
    @buffer_capacity = 1000
    @buffer1 = 0
    @time_machine_2_not_workning = 0

    schedule(new_lifetime, "Machine 1 is now broken", :machine_1_broke)
    schedule(new_lifetime, "Machine 3 is now broken", :machine_3_broke)

    done_in(10.hours) do
      debug("Time buffer empty: #{@time_machine_2_not_workning}")
    end
  end

  def machine_1_broke(time_passed)
    produced = 3 * time_passed
    reduced = - 2 * time_passed
    if produced - reduced + @buffer1 < @buffer_capacity
      @buffer1 +=  produced - reduced
    else
      @buffer1 = @buffer_capacity
    end

    schedule(new_lifetime * 1.5, "Machine 1 is now fixed", :machine_1_fixed)
  end

  def machine_3_broke(time_passed)
    produced = 3 * time_passed
    reduced = - 2 * time_passed
    # Buffer #b2 is not full
    if produced - reduced + @buffer2 < @buffer_capacity
      @buffer2 +=  produced - reduced
    # Buffer #b2 is full
    else
      @buffer2 = @buffer_capacity
    end

    schedule(new_lifetime * 1.5, "Machine 3 is now fixed", :machine_3_fixed)
  end

  def machine_3_fixed(time_passed)
    @buffer2 = @buffer2 - 2 * time_passed
    # Buffer was full a time ago
    # So #m2 must have been dead for @buffer2.abs seconds
    if @buffer2 < 0
      @time_machine_2_not_workning += @buffer2.abs
      @buffer2 = 0
    end

    debug("Buffer counter is now #{@buffer2}")

    schedule(new_lifetime, "Machine 3 is now broken", :machine_2_broke)
  end

  def machine_1_fixed(time_passed)
    @buffer = @buffer - 2 * time_passed
    if @buffer < 0
      @time_machine_2_not_workning += @buffer.abs
      @buffer = 0
    end

    debug("Buffer counter is now #{@buffer1}")

    schedule(new_lifetime, "Machine 1 is now broken", :machine_1_broke)
  end

  def new_lifetime
    rand(100).seconds
  end
end

Fruit.new