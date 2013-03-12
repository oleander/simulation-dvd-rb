require "./production"
require "state_machine"
require "debugger"
require "./machine"
require "./buffer"
require "./machine_group"

Infinity = 1/0.0

# (:machines, :id, :process_time, :p_buffer, :n_buffer)
class InjectionMoldingMachineGroup < MachineGroup

end

# (:id, :group)
class InjectionMoldingMachine < Machine

end

class DyeCoatingMachineGroup < MachineGroup

end

class DyeCoatingMachine < Machine
  
end

class SputteringMachineGroup < MachineGroup

end

class SputteringMachine < Machine

end

class LacquerCoatingMachineGroup < MachineGroup
  # 1. Must have at least one avalible machine
  # 2. Previous buffer must have 20 items
  # 3. Next buffer can't be full
  def can_produce?
    result = Struct.new(:status, :errors)
    errors = []
    status = true

    # 1.
    if avalible_machines.empty?
      status = false
      errors << "no machines avalible"
    end
    
    # 2.
    if p_buffer.current == 20
      status = false
      errors << "previous buffer do not have 20 items"
    end

    # 3.
    if n_buffer.full_including_reserved?
      status = false
      errors << "next buffer is full"
    end

    result.new(status, errors)
  end
end

class LacquerCoatingMachine < Machine

end

class PrintingMachineGroup < MachineGroup

end

class PrintingMachine < Machine

end

class DVD < Production
  def setup
    # Machine 1: im
    # Machine 2: dry
    # Machine 3: sputt, coat
    # Machine 4: print
    machines = {
      im: 4,
      dye: 2,
      sputt: 2,
      lac: 2,
      print: 2
    }

    max_buffers = [20, 20, 20, Infinity]
    process_times = [
      55.seconds, 
      5.seconds,
      2.seconds
    ]

    @buffers = buffers = max_buffers.each_with_index.map do |max_size, index|
      Buffer.new(max_size, index)
    end

    ####
    # Injection molding machines
    ####

    injection_molding_machine_group = InjectionMoldingMachineGroup.new(
      [], 
      "InjectionMolding", 
      55.seconds, 
      nil, # First machine do not have a buffer 
      buffers[0]
    )

    injection_molding_machines = machines[:im].times.map do |id|
      InjectionMoldingMachine.new(id, injection_molding_machine_group)
    end

    ####
    # Dye coating machines
    ####

    dye_coating_machine_group = DyeCoatingMachineGroup.new(
      [], 
      "DyeCoating", 
      10.seconds, 
      buffers[0], 
      buffers[1]
    )

    # Notify previous machine group about us
    injection_molding_machine_group.n_machine_group = dye_coating_machine_group
    dye_coating_machine_group.p_machine_group = injection_molding_machine_group

    dye_coating_machines = machines[:dye].times.map do |id|
      DyeCoatingMachine.new(id, dye_coating_machine_group)
    end

    ####
    # Sputtering machines
    ####

    @sputtering_machine_group = sputtering_machine_group = SputteringMachineGroup.new(
      [], 
      "Sputtering", 
      15.seconds, 
      buffers[1],
      buffers[2]
    )

    sputtering_machine_group.p_machine_group = dye_coating_machine_group
    dye_coating_machine_group.n_machine_group = sputtering_machine_group

    sputtering_machines = machines[:sputt].times.map do |id|
      SputteringMachine.new(id, sputtering_machine_group)
    end

    ####
    # Lacquer coating machines
    ####

    lacquer_coating_machine_group = LacquerCoatingMachineGroup.new(
      [], 
      "LacquerCoating", 
      15.seconds, 
      nil, # Do not not have any buffers
      nil
    )

    lacquer_coating_machines = machines[:lac].times.map do |id|
      LacquerCoatingMachine.new(id, lacquer_coating_machine_group)
    end

    ####
    # Printing machines
    ####

    @printing_machine_group = printing_machine_group = PrintingMachineGroup.new(
      [], 
      "Printing", 
      81.seconds, 
      buffers[2],
      buffers[3] # Last "fictional" buffer, a.k.a output
    )

    printing_machine_group.p_machine_group = sputtering_machine_group

    printing_machines = machines[:print].times.map do |id|
      PrintingMachine.new(id, printing_machine_group)
    end

    ####
    # Configuration
    ####

    done_in 1.day  do
      say(buffers.map(&:current).to_s, :red)
    end

    every_time do
      say(buffers.map(&:current).to_s, :yellow)
    end

    ####
    # Init
    ####

    injection_molding_machines.each do |machine|
      schedule(0.seconds, "Starting #{machine}", :start_machine_1, machine.group)
    end

    ####
    # Events
    ####
    #  start_machine_1
    #  machine_1_done

    #  start_machine_2
    #  machine_2_done

    #  machine_2_conveyor_belt

    #  start_sputtering_machine
    #  sputtering_machine_done

    #  start_coat_machine
    #  coat_machine_done

    #  start_conveyor_belt_for_coat
    #  conveyor_belt_for_coat_done

    #  start_machine_4
    #  machine_4_done

    #  machine_1_broke_down
    #  machine_1_fixed

    done_in(2.days) do
      say("We're now done!")
    end

    # -> machine_1_done
    def start_machine_1(machine_group, _)
      result = machine_group.can_produce?

      unless result.status
        return say("Could not start #{machine_group}. #{result.errors.join(", ")}", :red)
      end
      
      # Mark machine as started
      machine = machine_group.avalible_machines.first

      # Reserve space in next buffer
      machine_group.n_buffer.reserve

      # Start found machine
      machine.start!

      # Schedule finished machine
      schedule(machine_group.process_time, "Machine #{machine} is done", :machine_1_done, machine)
    end

    # --> start_machine_1
    # --> start_machine_2
    def machine_1_done(machine, _)
      # Remove reserved space in buffer
      machine.group.n_buffer.unreserve

      # Abort if:
      #   machine currently broken?
      #   machine is idle, a.k.a is has been broken but now fixed
      # TODO: Add nicer method to check if machine has been broken?
      if machine.broken? or machine.idle?
        return say("Ooops, machine #{machine} was broken before finished")
      end

      # Machine is not broken, increment next buffer
      machine.group.n_buffer.increment!

      # We're done, så machine is idel
      machine.idle!

      # Restart the machine?
      schedule(0, "Trying to restart #{machine.group}", :start_machine_1, machine.group)

      # Notify the dye coating machine group that an item just arrived
      if dye_coating_machine_group = machine.group.n_machine_group
        schedule(0, "Notify next machine (#{dye_coating_machine_group}) about new item", :start_machine_2, dye_coating_machine_group)
      else
        # TODO: Remove, only for debug purposes
        raise ArgumentError.new("Why don't 1 have neighbor?")
      end
    end

    # -> machine_2_done
    # --> start_machine_1
    def start_machine_2(machine_group, _)
      result = machine_group.can_produce?

      unless result.status
        return say("Could not start #{machine_group} due to #{result.errors.join(", ")}", :red)
      end
      
      # Mark machine as started
      machine = machine_group.avalible_machines.first

      # Decrement previous buffer (we're taking one item)
      machine_group.p_buffer.decrement!

      machine_group.n_buffer.reserve

      machine.start!

      # Schedule finished machine
      schedule(machine_group.process_time, "Machine #{machine} is done", :machine_2_done, machine)

      # Tell the injection molding machine group to start
      if injection_molding_machine_group = machine_group.p_machine_group
        schedule(0, "Notify previous machine (#{injection_molding_machine_group}) about item removed from buffer", :start_machine_1, injection_molding_machine_group)
      else
        # TODO: Remove, only for debug purposes
        raise ArgumentError.new("Why don't 2 have a previous machine?")
      end
    end

    # --> start_machine_2
    # -> machine_2_conveyor_belt
    def machine_2_done(machine, _)
      # Abort if:
      #   machine currently broken?
      #   machine is idle, a.k.a is has been broken but now fixed
      # TODO: Add nicer method to check if machine has been broken?
      if machine.broken? or machine.idle?
        return say("Ooops, machine #{machine} was broken before finished")
      end

      # Mark machine as idle
      machine.idle!

      # Schedule conveyor belt done
      schedule(5.minutes, "One item just fell of conveyor belt #1", :machine_2_conveyor_belt, machine.group)
    end

    # --> start_sputtering_machine
    def machine_2_conveyor_belt(group, _)
      group.n_buffer.unreserve

      # An item just fell of the conveyor belt
      group.n_buffer.increment!

      # Trying to start the sputtering machine
      schedule(0, "Trying to start sputtering machine", :start_sputtering_machine, group.n_machine_group)
    end

    # -> sputtering_machine_done
    def start_sputtering_machine(machine_group, _)
      result = machine_group.can_produce?

      unless result.status
        return say("Could not start #{machine_group} due to #{result.errors.join(", ")}", :red)
      end

      # TODO: Move logic into buffer and machine group class
      if machine_group.p_buffer.current - 20 < 0
        return say("Could not start #{machine_group}, previous buffer almost empty")
      end

      if machine_group.n_buffer.current + 20 > machine_group.n_buffer.size
        return say("Could not start #{machine_group}, next buffer almost full")
      end

      # Decrement previous buffer by 20
      machine_group.p_buffer.decrement!(20)

      # Reserve 20 spots in next buffer
      machine_group.n_buffer.reserve(20)

      # Select first avalible machine
      machine = machine_group.avalible_machines.first

      # Mark machine as started
      machine.start!

     # Tell the dye coating machine group to start
      if dye_coating_machine_group = machine_group.p_machine_group
        schedule(0, "Notify previous machine (#{dye_coating_machine_group}) about item removed from buffer", :start_machine_2, dye_coating_machine_group)
      else
        # TODO: Remove, only for debug purposes
        raise ArgumentError.new("Why don't 3 have a previous machine?")
      end

      schedule(10.minutes, "Sputtering machine #{machine} done", :sputtering_machine_done, machine)
    end

    # --> start_sputtering_machine
    # --> start_coat_machine
    def sputtering_machine_done(machine, _)
      # Mark machine as idle
      machine.idle!

      # Schedule conveyor belt done
      schedule(0, "One batch just finished in sputtering machine #{machine}", :start_coat_machine)
    end

    # -> coat_machine_done
    def start_coat_machine(_)
      schedule(6.seconds * 20, "Coat machine done", :coat_machine_done)
    end

    # --> start_coat_machine
    # --> start_conveyor_belt_for_coat
    def coat_machine_done(_)
      schedule(0, "Placing 20 items in conveyor belt", :start_conveyor_belt_for_coat)
    end

    # -> conveyor_belt_for_coat_done
    def start_conveyor_belt_for_coat(_)
      schedule(3.minutes, "20 items just fell of the conveyor belt", :conveyor_belt_for_coat_done)
    end

    # --> start_machine_4
    def conveyor_belt_for_coat_done(_)
      buffer = @buffers[2]
      buffer.unreserve(20)
      buffer.increment!(20)
      schedule(0, "Trying to start machine 4", :start_machine_4)
    end

    # -> machine_4_done
    def start_machine_4(_)
      machine_group = @printing_machine_group
      result = machine_group.can_produce?

      unless result.status
        return say("Could not start #{machine_group} due to #{result.errors.join(", ")}", :red)
      end

      # Decrement previous buffer by 20
      # TODO: Make it possible to decrement by 20 without the loop
      machine_group.p_buffer.decrement!

      # Select first avalible machine
      machine = machine_group.avalible_machines.first

      # Mark machine as started
      machine.start!

     # Tell the sputtering machine group to start
      if sputtering_machine_group = machine_group.p_machine_group
        schedule(0, "Notify previous machine (#{sputtering_machine_group}) about item removed from buffer", :start_sputtering_machine, sputtering_machine_group)
      else
        # TODO: Remove, only for debug purposes
        raise ArgumentError.new("Why don't 4 have a previous machine?")
      end

      schedule(10.minutes, "#{machine} done", :machine_4_done, machine)
    end

    # --> start_machine_4
    def machine_4_done(machine, _)
      # Machine is not broken, increment next buffer
      machine.group.n_buffer.increment!

      # We're done, så machine is idel
      machine.idle!

      # Restart the machine?
      schedule(0, "Trying to restart #{machine.group}", :start_machine_4)
    end

    # -> machine_1_fixed
    def machine_1_broke_down(_)
      
    end

    # -> machine_1_broke_down
    # --> start_machine_1
    def machine_1_fixed(_)
      
    end
  end
end

DVD.new