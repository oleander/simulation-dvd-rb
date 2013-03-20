require "optparse"
require "gnuplot"
require "hirb"
require "pp"
require "thread"
require "json"
semaphore = Mutex.new
require_relative "./dvd"
require_relative "./filter"

options = {
  machines: {
    im: 4,
    dye: 2,
    sputt: 2,
    lac: 2,
    print: 2
  },
  buffers: [20, 20, 20, Infinity],
  runtime: 2,
  quiet: false
}

OptionParser.new do |opts|
  opts.banner = "Usage: simulation.rb [options]"

  opts.on("-im", "--im", "Injection molding machine", Integer) do |v|
    if v < 1
      raise ArgumentError.new("Min amount of injection machines are 1")
    end
    options[:machines][:im] = v
  end

  opts.on("-quiet", "--quiet", "Quiet", Integer) do |v|
    unless [0,1].include?(v)
      raise ArgumentError.new("Valid options to quiet are 0 and 1")
    end

    options[:quiet] = v == 1
  end

  opts.on("-dye", "--dye", "Dye coating and drying machine", Integer) do |v|
    if v < 1
      raise ArgumentError.new("Min amount of drying machines are 1")
    end
    options[:machines][:dye] = v
  end

  opts.on("-sputt", "--sputt", "Sputtering machine", Integer) do |v|
    if v < 1
      raise ArgumentError.new("Min amount of sputtering machines are 1")
    end

    options[:machines][:sputt] = v
  end

  opts.on("-lac", "--lac", "Lacquer coating machine", Integer) do |v|
    if v < 1
      raise ArgumentError.new("Min amount of lacquer coating machines are 1")
    end
    options[:machines][:lac] = v
  end

  opts.on("-print", "--print", "Print machine", Integer) do |v|
    if v < 1
      raise ArgumentError.new("Min amount of printing machines are 1")
    end

    options[:machines][:print] = v
  end

  opts.on("-runtime", "--runtime", "Runtime in hours", Integer) do |v|
    if v < 1
      raise ArgumentError.new("Runtime must be > 0")
    end

    options[:runtime] = v
  end

  opts.on("-buffers", "--buffers", "Buffers", Array) do |v|
    buffers = v.map(&:to_i)
    unless buffers.length == 3
      raise ArgumentError.new("3 buffers must be passed")
    end

    if buffers[1] % 20 != 0 or buffers[2] % 20 != 0
      raise ArgumentError.new("Buffer #2 and #3 must be a multiple of 20")
    end

    if buffers.any?{|b| b <= 0}
      raise ArgumentError.new("A buffer size of zero or less is not allowed")
    end

    options[:buffers] = (buffers.map(&:to_i) << Infinity)
  end
end.parse!

# container = Struct.new(:thruput, :production, :variance_thruput, :variance_production)
# results  = []
# threads = []
options = []

(20..100).step(40) do |b1|
  (20..100).step(40) do |b2|
    (20..100).step(40) do |b3|
      (4..5).each do |im|
        (2..3).each do |dye|
          (2..3).each do |sputt|
            (2..3).each do |print|
              options << {
                machines: {
                  im: im,
                  dye: dye,
                  sputt: sputt,
                  lac: 2, # Isn't used
                  print: print
                },
                buffers: [b1, b2, b3, Infinity],
                runtime: 24*4,
                quiet: true
              }
            end
          end
        end
      end
    end
  end
end

threads = []
start = lambda {
  threads << Thread.new do
    option = nil
    next if options.empty?
    semaphore.synchronize {
      option = options.shift
    }

    buffers = DVD.new(option[:machines], option[:buffers], option[:runtime], option[:quiet]).execute![:buffers]
    # pp buffers.last.items.map(&:done_at)
    items = buffers.last.items
    stats = Filter.new(items, 250, option[:runtime]).process!
    semaphore.synchronize {
      puts option.merge(stats).merge({
        buffers: buffers.map(&:as_json)
      }).to_json

      puts "----------------"
      # results << container.new(stats[:thruput], stats[:production], stats[:variance_thruput], stats[:variance_production])
      # puts results.length
    }

    start.call
  end
}

options = options[0..1]
puts options.length

1.times do
  start.call
end

threads.each(&:join)

# extend Hirb::Console
# Hirb.enable({pager: false})
# table(results, fields: [:thruput, :variance_thruput, :production, :variance_production])

# buffers = DVD.new(options[:machines], options[:buffers], options[:runtime], options[:quiet]).execute!

# pp buffers


# Gnuplot.open do |gp|
#   Gnuplot::Plot.new( gp ) do |plot|
#     plot.yrange "[0:140]"
#     plot.xrange "[0:1440]"
#     plot.title  "Items"
#     plot.xlabel "Minutes"
#     plot.ylabel "Average [Production time in min / item]"
    
#     x = a.keys
#     y = a.values.map(&:average)

#     plot.data << Gnuplot::DataSet.new( [x, y] ) do |ds|
#       ds.with = "linespoints"
#       ds.notitle
#     end
#   end
# end