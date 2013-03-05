require "priority_queue"
require "active_support/core_ext/integer"
require "colorize"
require "timecop"
require "time"

class Production
  def initialize
    @queue = PriorityQueue.new
    @event = Struct.new(:name, :block, :arguments)
    Timecop.freeze(Time.parse("2013-03-05 00:00"))
    @done = false
    execute!
  end

  protected

  def debug(message)
    $stdout.puts "[%s] %s" % [
      Time.now.strftime("%H:%M:%S").green, 
      message.blue
    ]
  end

  def schedule(time, name, *args, &block)
    @queue[@event.new(name, block, args)] = time.from_now
  end

  def done!
    @done = true
  end

  def say(message)
    debug(message)
  end

  private

  def execute!
    init
    loop do
      action

      if done?
        debug("We're not done, bye!"); break
      end

      if no_more_events?
        debug("No more events to execute, exiting"); break
      end

      execute_next_event
    end
  end

  # Abstract method
  def init
    # debug("Init method not implemented")
  end

  def action
    raise "action method not implemented"
  end

  def execute_next_event
    event, time = @queue.delete_min
    Timecop.freeze(time)
    debug("#{event.name}")
    event.block.call(*event.arguments)
  end

  def no_more_events?
    @queue.empty?
  end

  def done?
    @done
  end
end