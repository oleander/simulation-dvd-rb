require "./production"
require "state_machine"
require "debugger"
require "./machine"
require "./buffer"
require "./machine_group"

class ThreeMachines < Production
  Infinity = 1/0.0

  def setup
    max_buffers = [5, 5, Infinity]
    process_times = [
      10.seconds, 
      5.seconds,
      10.seconds
    ]
    machines = [
      2, 
      2, 
      2
    ]

    buffers = max_buffers.each_with_index.map do |max_size, index|
      Buffer.new(max_size, index)
    end

    machines_groups = []
    machines.each_with_index.map do |amount_of_machines, group_id|
      # First machine?
      if group_id.zero?
        p_b = nil
        n_b = buffers.first
      else
        p_b = buffers[group_id - 1]
        n_b = buffers[group_id]
      end

      process_time = process_times[group_id]
      group = MachineGroup.new([], group_id, process_time, p_b, n_b)
      amount_of_machines.times do |machine_id|
        group.add(Machine.new(machine_id, group))
      end

      machines_groups << group
    end

    machines_groups.each_with_index do |machines_group, index|
      # First machine?
      if index.zero?
        machines_group.n_machine_group = machines_groups[index + 1]
      elsif machines_groups.length - 1 == index # Last machine
        machines_group.p_machine_group = machines_groups[index - 1]
      else # In between
        machines_group.n_machine_group = machines_groups[index + 1]
        machines_group.p_machine_group = machines_groups[index - 1]
      end
    end

    # Start first machine
    machines_groups.first.machines.each do |machine|
      schedule(0.seconds, "Try to start machine group #{machine.group}", :try_to_start_machine_group, machine.group)
    end

    [machines_groups.first, machines_groups.last].each do |group| 
      group.machines.each do |machine|
        schedule(0.seconds, "Initialize broke sequence for #{machine.group}", :machine_fixed, machine)
      end
    end

    done_in 30.minutes  do
      say(buffers.map(&:current).to_s, :red)
    end

    every_time do
      say(buffers.map(&:current).to_s, :yellow)
    end

    # delay(5.second)
  end

  def try_to_start_machine_group(machine_group, time_diff)
    result = machine_group.can_produce?

    unless result.status
      return say("Could not start #{machine_group} due to #{result.errors.join(", ")}", :red)
    end
    
    # Mark machine as started
    machine = machine_group.avalible_machines.first

    # Decrement previous buffer (we're taking one item)
    machine_group.adjust_buffer!(:previous)

    machine_group.n_buffer.reserve

    machine.start!

    # Schedule finished machine
    schedule(machine_group.process_time, "Machine #{machine} is done", :machine_done, machine)

    # Tell previous machine to start
    if p_machine_group = machine_group.p_machine_group
      schedule(0, "Notify previous machine (#{p_machine_group}) about item removed from buffer", :try_to_start_machine_group, p_machine_group)
    end
  end

  def machine_done(machine, _)
    machine.group.n_buffer.unreserve

    if machine.broken?
      return say("Ooops, machine #{machine} was broken before finished")
    end

    # Machine is not broken, increment next buffer
    machine.group.adjust_buffer!(:next)

    # Mark machine as idle
    machine.idle!

    # Restart the machine?
    schedule(0, "Trying to restart #{machine.group}", :try_to_start_machine_group, machine.group)

    # Does the machine group has a next machine?
    if n_machine_group = machine.group.n_machine_group
      schedule(0, "Notify next machine (#{n_machine_group}) about new item", :try_to_start_machine_group, n_machine_group)
    end
  end

  def machine_broken(machine, _)
    machine.break!
    schedule(20.seconds, "Machine #{machine} is now fixed", :machine_fixed, machine)
  end

  def machine_fixed(machine, _)
    if machine.broken?
      machine.fix!
    else
      say("Strange, machine #{machine} is not broken, first run?", :red)
    end
    
    schedule(0, "Trying to start #{machine} after breakdown", :try_to_start_machine_group, machine.group)
    schedule(5.minutes, "Machine #{machine} just broke down, darn!", :machine_broken, machine)
  end
end

ThreeMachines.new