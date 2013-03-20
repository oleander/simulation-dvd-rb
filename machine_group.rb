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
  def can_produce?(amount = 1)
    result = Struct.new(:status, :errors)
    errors = []
    status = true

    # 1.
    if avalible_machines.empty?
      status = false
      errors << "no machines avalible"
    end
      
    if status
      if p_buffer
        p_buffer.inc(:do)
      end
    end

    # 2.
    if p_buffer and not p_buffer.can_take_items?(amount) and status
      p_buffer.inc(:emptyness)
      status = false
      errors << "previous buffer is empty"
    end

    if status
      n_buffer.inc(:do)
    end

    # 3.
    if not n_buffer.has_space_for?(amount, include_reserved: true) and status
      n_buffer.inc(:fullness)
      status = false
      errors << "next buffer is full"
    end

    result.new(status, errors)
  end

  def to_s
    id.to_s
  end

  def inspect
    to_s
  end
end