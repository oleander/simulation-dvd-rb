require "./production"

class DVD < Production
  def setup
    done_in(2 * 24.hours) do
      say("We're now done!")
    end

    schedule(2.hours, "Machine 1 broken", :machine_1_broke)
  end

  # Called when wachine 1 is broken
  def machine_1_broke(time_since_called)
    # Calculate when buffer b2 has 20 items in it
    schedule(0.minute, "Buffer 2 has now 20 items", :buffer_2_has_20_items)
    schedule(5.minute, "Machine 1 is now fixed", :machine_1_is_fixed)
  end

  # Machine one is fixed
  def machine_1_is_fixed(time_since_called)
    schedule(2.hours, "Machine 1 broken", :machine_1_broke)
    schedule(0.minute, "Buffer 2 has now 20 items", :buffer_2_has_20_items)
  end

  # 20 items now exists in buffer 2
  def buffer_2_has_20_items(time_since_called)
    # Decrement buffer 2 with 20
    # Calculate when sputtering is done, including being stuck
    # Start sputtering machine, or stand in queue
    schedule(5.minutes, "Start sputtering machine", :start_sputtering_machine)
  end

  # Start sputtering machine
  def start_sputtering_machine(time_since_called)
    # Calculate time when sputtering machine to be done
    schedule(5.minutes, "Sputtering machine is now done", :sputtering_machine_is_done)
  end

  # Called when sputtering machine is done
  def sputtering_machine_is_done(time_since_called)
    # If there is a queue, decrement buffer with 20 and start machine again
    schedule(0.minutes, "Start sputtering again, without break", :start_sputtering_machine)
    schedule(0.minutes, "Start coat machine", :start_coat_machine)
  end

  # Start coat machine
  def start_coat_machine(time_since_called)
    schedule(10.minutes, "Coat machine i now done", :lack_machine_is_done)
  end

  def lack_machine_is_done(time_since_called)
    # If there is a queue, decrement queue with one and start machine again
    schedule(0.minutes, "Start coat machine", :start_coat_machine)
  end
end

DVD.new