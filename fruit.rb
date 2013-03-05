require "./production"

class Fruit < Production
  def init
    @bufferCap = 1000
    @bufferCur = 0
    @time_buffer_empty = 0
    @machine_1_started_at = current_time
    schedule(new_lifetime, "Machine 1 is now broken", :machine_1_broken)
    done_in(1.hour) do
      debug("Time buffer is empty: #{@time_buffer_empty}")
    end
  end

  def machine_1_broken
    time_passed = (current_time - @machine_1_started_at).to_i
    produced = 3 * time_passed
    reduced = - 2 * time_passed
    if produced - reduced + @bufferCur < @bufferCap
      @bufferCur +=  produced - reduced
      debug("New buffer value is #{@bufferCur}")
    else
      @bufferCur = @bufferCap
      debug("Buffer is full #{@bufferCur}")
    end

    @machine_1_broken_at = current_time
    schedule(new_lifetime, "Machine 1 is now fixed", :machine_1_fixed)
  end

  def machine_1_fixed
    @bufferCur = @bufferCur - 2 * (current_time - @machine_1_broken_at).to_i
    if @bufferCur < 0
      @time_buffer_empty += @bufferCur.abs
      @bufferCur = 0
    end

    debug("Buffer counter is not #{@bufferCur}")

    @machine_1_started_at = current_time
    schedule(new_lifetime, "Machine 1 is now broken", :machine_1_broken)
  end

  def new_lifetime
    rand(100).seconds
  end
end

Fruit.new