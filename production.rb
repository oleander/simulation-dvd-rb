require "pqueue"
require "active_support/all"
require "colorize"
require "timecop"
require "time"

module Calculation
  def self.exp(lambda)
     (-1 * Math.log(1 - rand) * lambda.to_i).seconds
  end
end

class Production
  attr_reader :loops
  
  def initialize(quiet = false)
    @queue      = PQueue.new { |a,b| a.time < b.time }
    @event      = Struct.new(:name, :callback, :arguments, :seed, :time)
    @delay      = nil
    @loops      = 0
    @done       = false
    @quiet      = quiet
    @start_time = Time.parse("00:00")

    jump_to(@start_time)
  end

  def execute!
    setup

    next_time = nil

    loop do
      @loops += 1
      if done?
        debug("We're now done, bye!"); break
      end

      if no_more_events?
        debug("No more events to execute, exiting"); break
      end

      if @done_in < current_time or next_sched_time > @done_in
        debug("Done according to done_in"); break
      end

      # Execute next event
      execute_next_event

      @every_time.call if @every_time

      # Did this event have the same time as the last one?
      current_event_time = next_time
      next_time = next_sched_time

      # Should we group them?
      if next_time != current_event_time and current_event_time
        sleep @delay if @delay
        debug("\n")
      end
    end

    if @done_in_block
      @done_in_block.call
    end

    return @returns.call if @returns
  end

  protected

  def debug(message, color = :blue)
    return if @quiet
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

  def returns(&block)
    @returns = block
  end

  def delay(seconds)
    @delay = seconds
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

  alias_method :say, :debug

  def current_time
    Time.now
  end

  def every_time(&block)
    @every_time = block
  end

  private

  def jump_to(time)
    Timecop.freeze(time)
  end

  # Abstract method
  def setup
    debug("#setup not implemented")
  end

  def execute_next_event
    event = @queue.pop
    time = event.time
    
    jump_to(time)

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

  def next_sched_time
    event = @queue.top
    event ? event.time : -1
  end
end
