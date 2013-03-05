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
    schedule(2.hours, "random") do
      schedule(5.minutes, "random") { puts "DO MORE!"}
    end
  end

  def execute!
    loop do
      if done?
        debug("We're not done, bye!")
      end

      if no_more_events?
        debug("No more events to execute, exiting"); break
      end

      execute_next_event
    end
  end

  def execute_next_event
    event, time = @queue.delete_min
    Timecop.freeze(time)
    debug("Execute #{event.name} with #{event.arguments.length} arguments")
    event.block.call(*event.arguments)
  end

  def no_more_events?
    @queue.empty?
  end

  def done?
    false
  end

  def debug(message)
    $stdout.puts "[%s] %s" % [
      Time.now.strftime("%H:%M:%S").green, 
      message.blue
    ]
  end

  def schedule(time, name, *args, &block)
    @queue[@event.new(name, block, args)] = time.from_now
  end
end

Production.new.execute!