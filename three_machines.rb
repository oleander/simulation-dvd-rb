require "./production"
require "state_machine"
require "debugger"

class Machine < Struct.new(:id, :group, :buffer)
  state_machine :state, initial: :idle do
    event :start do
      transition [:idle, :break] => :start
    end

    event :break do
      transition [:start] => :break
    end

    event :idle do
      transition [:break, :start] => :idle
    end

    event :fix do
      transition [:break] => :idle
    end
  end

  def process_time
    group.process_time
  end

  def broken?
    break?
  end

  def say(message, color = :red)
    puts "Machine #{group_id}.#{id}: #{message}".send(color)
  end

  def to_s
    name
  end

  def name
    "#{group.id}.#{id}"
  end
end

class Buffer
  attr_reader :current, :size, :id

  def initialize(size, id)
    @id      = id
    @size    = size
    @reserve = 0
    @current =  0
  end

  def increment!
    if full?
      raise ArgumentError.new("Can't increment full buffer #{id}")
    end

    @current += 1
  end

  def decrement!
    if empty?
      raise ArgumentError.new("Can't decrement empty buffer #{id}")
    end

    @current -= 1
  end

  #
  # @return Boolean Is buffer empty?
  #
  def empty?
    return @current.zero?
  end

  #
  # @return Boolean Is buffer full?
  #
  def full?
    return @current >= @size
  end

  def full_including_reserved?
    @current + @reserve == size
  end

  def unreserve
    @reserve -= 1
  end

  def reserve
    @reserve += 1
  end

  def to_s
    "<Buffer id: #{@id}, current: #{@current}, size: #{@size}>"
  end

  def inspect
    to_s
  end
end

class MachineGroup < Struct.new(:machines, :id, :process_time, :p_buffer, :n_buffer)
  attr_accessor :n_machine_group, :p_machine_group

  #
  # @machine Machine Adds machine to group
  #
  def add(machine)
    machines.push(machine)
  end

  #
  # @return Array<Machine> A list of avalible machines
  #
  def avalible_machines
    machines.select(&:idle?)
  end

  #
  # @return Boolean Can this machine group price any items?
  #

  # 1. Must have at least one avalible machine
  # 2. Previous buffer can't be empty
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
    if p_buffer and p_buffer.empty?
      status = false
      errors << "previous buffer is empty"
    end

    # 3.
    if n_buffer.full_including_reserved?
      status = false
      errors << "next buffer is full"
    end

    result.new(status, errors)
  end

  def adjust_buffer!(where)
    case where
    when :next
      n_buffer.increment!
    when :previous
      p_buffer && p_buffer.decrement!
    else
      raise InvalidArgumentError.new("Invalid 'where' value: #{where}")
    end
  end

  def to_s
    id.to_s
  end

  def inspect
    to_s
  end
end

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

    done_in 2.minutes  do
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
      schedule(0.seconds, "Try to start machine group #{p_machine_group}", :try_to_start_machine_group, p_machine_group)
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
    schedule(0, "Trying to start machine group #{machine.group}", :try_to_start_machine_group, machine.group)

    # Does the machine group has a next machine?
    if n_machine_group = machine.group.n_machine_group
      schedule(0, "Trying to start machine group #{n_machine_group}", :try_to_start_machine_group, n_machine_group)
    end
  end
end

ThreeMachines.new