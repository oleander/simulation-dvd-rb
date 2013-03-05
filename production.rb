require "priority_queue"
require "active_support/core_ext/integer"
require "colorize"
require "timecop"
require "time"
require "debugger"

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
      message.to_s.blue
    ]
  end

  def done_in(time, &block)
    @done_in = time.from_now
    @done_in_block = block
  end

  def schedule(time, name, *args, &block)
    unless block_given?
      block = args.pop
    end

    @queue[@event.new(name, block, args)] = time.from_now
  end

  def done!
    @done = true
  end

  def say(message)
    debug(message)
  end

  def current_time
    Time.now
  end

  private

  def execute!
    init
    loop do
      execute_next_event
      action
      if done?
        debug("We're not done, bye!"); break
      end

      if no_more_events?
        debug("No more events to execute, exiting"); break
      end

      if @done_in < current_time
        if @done_in_block
          @done_in_block.call
        end
        debug("Done according to done_in"); break
      end
    end
  end

  # Abstract method
  def init
    # debug("Init method not implemented")
  end

  def action
    # debug("Action is not implemented")
  end

  def execute_next_event
    event, time = @queue.delete_min
    Timecop.freeze(time)
    debug("#{event.name}")
    case event.block
    when Symbol
      send(event.block, *event.arguments)
    else
      event.block.call(*event.arguments)
    end
  end

  def no_more_events?
    @queue.empty?
  end

  def done?
    @done
  end
end