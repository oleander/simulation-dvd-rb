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

    buffers = max_buffers.each_with_index.map do |max_size, index|
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

    dye_coating_machines = machines[:dye].times.map do |id|
      DyeCoatingMachine.new(id, dye_coating_machine_group)
    end

    ####
    # Sputtering machines
    ####

    sputtering_machine_group = SputteringMachineGroup.new(
      [], 
      "Sputtering", 
      15.seconds, 
      buffers[1],
      nil # We do not have a next buffer
    )

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

    printing_machine_group = PrintingMachineGroup.new(
      [], 
      "Printing", 
      81.seconds, 
      buffers[2],
      buffers[3] # Last "fictional" buffer, a.k.a output
    )

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
      
    end

    # -> machine_2_done
    # --> start_machine_1
    def start_machine_2(_)
      
    end

    # --> start_machine_2
    # -> machine_2_conveyor_belt
    def machine_2_done(_)
      
    end

    # --> start_sputtering_machine
    def machine_2_conveyor_belt(_)
      
    end

    # -> sputtering_machine_done
    def start_sputtering_machine(_)
      
    end

    # --> start_sputtering_machine
    # --> start_coat_machine
    def sputtering_machine_done(_)
      
    end

    # -> coat_machine_done
    def start_coat_machine(_)
      
    end

    # --> start_coat_machine
    # --> start_conveyor_belt_for_coat
    def coat_machine_done(_)
      
    end

    # -> conveyor_belt_for_coat_done
    def start_conveyor_belt_for_coat(_)
      
    end

    # --> start_machine_4
    def conveyor_belt_for_coat_done(_)
      
    end

    # -> machine_4_done
    def start_machine_4(_)
      
    end

    # --> start_machine_4
    def machine_4_done(_)
      
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