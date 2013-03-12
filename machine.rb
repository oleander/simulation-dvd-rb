class Machine
  attr_reader :id, :group

  def initialize(id, group)
    @id, @group = id, group
    # Add our self to machine group
    group.add(self)
    super() # For the statemachine gem
  end

  state_machine :state, initial: :idle do
    event :start do
      transition [:idle, :break] => :start
    end

    event :break do
      transition [:start, :idle] => :break
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