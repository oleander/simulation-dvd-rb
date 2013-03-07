require "./production"

class DVD < Production
  def setup
    # Macine 1: im
    # Machine 2: dry
    # Machine 3: sputt, coat
    # Machine 4: print
    @machines = {
      im: 4,
      dry: 2,
      sputt: 2,
      coat: 2,
      print: 2
    }

    done_in(10.hours) do
      say("We're now done!")
    end

    @machines[:im].times do |id|
      schedule(rand(10).minutes, "A machine is broken", :machine_broke)
    end
  end

  # Called when wachine 1 is broken
  def machine_broke(time_since_called)
    # Calculate when buffer b2 has 20 items in it
    # schedule(0.minute, "Buffer 2 has now 20 items", :buffer_2_has_20_items)
    schedule(rand(10).minutes, "A machine is fixed", :machine_fixed)

    # Mark one machine as broken
    @machines[:im] -= 1
  end

  # Machine one is fixed
  def machine_fixed(time_since_called)
    schedule(rand(10).minutes, "A machine is broken", :machine_broke)
    # schedule(0.minute, "Buffer 2 has now 20 items", :buffer_2_has_20_items)

    # Mark one machine as fixed
    @machines[:im] += 1
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