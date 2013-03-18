require "optparse"
require "gnuplot"
require_relative "./dvd"

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

result = DVD.new(options[:machines], options[:buffers], options[:runtime], options[:quiet]).execute!
items = result[:items]

class R < Struct.new(:amount, :total_time)
  def average
    ((total_time / amount.to_f) / 60.0).round
  end
end

start_time = items.first.created_at
a = items.inject({}) do |result, item|
  key = ((item.done_at.to_i - start_time.to_i) / (60.0)).round
  result[key] ||= R.new(0, 0)
  result[key].total_time += item.production_time
  result[key].amount += 1
  result
end

Gnuplot.open do |gp|
  Gnuplot::Plot.new( gp ) do |plot|
    plot.yrange "[0:140]"
    plot.xrange "[0:1440]"
    plot.title  "Items"
    plot.xlabel "Minutes"
    plot.ylabel "Average [Production time in min / item]"
    
    x = a.keys
    y = a.values.map(&:average)

    plot.data << Gnuplot::DataSet.new( [x, y] ) do |ds|
      ds.with = "linespoints"
      ds.notitle
    end
  end
end