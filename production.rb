require "pqueue"
require "active_support/all"
require "colorize"
require "timecop"
require "time"
require "debugger"

class Production
  def initialize
    @queue = PQueue.new { |a,b| a.time < b.time }
    @event = Struct.new(:name, :callback, :arguments, :seed, :time)

    @start_time = Time.parse("00:00")
    Timecop.freeze(@start_time)
    @done = false
    execute!
  end

  protected

  def debug(message, color = :blue)
    days_passed = ((current_time - @start_time) / (60 * 60 * 24)).to_i
    time = "%s day%s %s".green % [
      days_passed.to_s,
      days_passed > 1 || days_passed.zero? ? "s" : "",
      current_time.strftime("%H:%M:%S")
    ]
    $stdout.puts "[%s] %s" % [
      time,
      message.to_s.send(color)
    ]
  end

  def done_in(time, &block)
    @done_in = time.from_now
    @done_in_block = block
  end

  def schedule(time, name, *args, &callback)
    unless block_given?
      callback = args.shift
    end

    args << current_time
    @queue.push(@event.new(name, callback, args, rand(1000), time.from_now))
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
    setup
    loop do
      if done?
        debug("We're now done, bye!"); break
      end

      if no_more_events?
        debug("No more events to execute, exiting"); break
      end

      if @done_in < current_time or @queue.top.time > @done_in
        debug("Done according to done_in"); break
      end

      execute_next_event
    end

    if @done_in_block
      @done_in_block.call
    end
  end

  # Abstract method
  def setup
    debug("#setup not implemented")
  end

  def execute_next_event
    event = @queue.pop
    time = event.time
    
    Timecop.freeze(time)

    debug(event.name)

    started_at = event.arguments.pop
    event.arguments << (current_time - started_at).to_i

    case event.callback
    when Symbol
      send(event.callback, *event.arguments)
    else
      event.callback.call(*event.arguments)
    end
  end

  def no_more_events?
    @queue.empty?
  end

  def done?
    @done
  end
end