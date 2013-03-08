require "./production"

class ThreeMachines < Production
  Infinity = 1/0.0

  def setup
    @original_machines = @machines = [10, 1, 3] 
    @buffers = [0, 0, 0]
    @max_buffers = [30, 15, Infinity]
    @process_times = [
      60.seconds, 
      2.seconds,
      41.seconds
    ]

    # Start first machine
    @machines.first.times do
      schedule(0.seconds, "Try to start machine 0", :try_to_start_machine, 0)
    end

    done_in 5.hours  do
      say(@buffers.inspect, :red)
    end

    delay(2.second)

    every_time do
      say(@buffers.inspect, :green)
    end
  end

  def machine_done(machine, _)
    say("Machine #{machine} is now done", :yellow)

    # Add one created item to batch
    finished!(machine)

    # Not last machine?
    unless last_machine?(machine)
      schedule(0.seconds, "Trying to start machine #{machine + 1}", :try_to_start_machine, machine + 1)
    end

    schedule(0.seconds, "Trying to start machine #{machine}", :try_to_start_machine, machine)
  end

  def try_to_start_machine(machine, _)
    # Buffer 1 is not full
    if can_produce?(machine)
      say("Start machine #{machine}")
      start!(machine) # Start machine and decrement buffer with one
      schedule(@process_times[machine], "Machine #{machine} done", :machine_done, machine)
    else
      say("Could not start machine #{machine}", :red)
    end
  end

  #
  # @machine Integer
  #
  def last_machine?(machine)
    @machines.length == machine + 1
  end

  #
  # @machine Integer 
  #
  def can_produce?(machine)
    # Is this the first buffer?
    if machine.zero?
      prev = true
    else
      prev = @buffers[machine - 1] > 0
    end

    buffers_ok = [
      prev, # Prev. buffer can not be empty
      @buffers[machine] < @max_buffers[machine] # Next buffer not be full
    ].all?

    return (buffers_ok and avalible?(machine))
  end

  def start!(machine)
    unless can_produce?(machine)
      raise "machine can't produce anything"
    end

    # Mark one machine as taken
    reserve!(machine)

    # Decrement prev. buffer with one
    # First machine does not have a buffer
    unless machine.zero?
      take_from_buffer!(machine)
    end
  end

  def finished!(machine)
    # Increment next buffer by one
    add_to_buffer(machine)

    # Mark machine as done
    unreserve!(machine)
  end

  def add_to_buffer(machine)
    if @buffers[machine] > @max_buffers[machine]
      raise "Buffer #{machine} is full"
    end

    @buffers[machine] += 1
  end

  def take_from_buffer!(machine)
    index = machine - 1
    if @buffers[index].zero?
      raise "Buffer #{index} is empty"
    end

    @buffers[index] -= 1
  end

  #
  # @machine Integer
  #
  def reserve!(machine)
    unless avalible?(machine)
      raise "There are no more #{machine} machines"
    end

    @machines[machine] -= 1
  end

  def unreserve!(machine)
    if @original_machines[machine] < @machines[machine]
      raise "Machine #{machine} has never been reserved"
    end

    @machines[machine] += 1
  end

  #
  # @machine Integer
  #
  def avalible?(machine)
    ! @machines[machine].zero?
  end
end

ThreeMachines.new