require "optparse"
require_relative "./dvd"

options = {
  machines: {
    im: 4,
    dye: 2,
    sputt: 2,
    lac: 2,
    print: 2
  },
  buffers: [20, 20, 20, Infinity]
}

OptionParser.new do |opts|
  opts.banner = "Usage: simulation.rb [options]"

  opts.on("-im", "--im", "Injection molding machine", Integer) do |v|
    if v < 1
      raise ArgumentError.new("Min amount of injection machines are 1")
    end
    options[:machines][:im] = v
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

DVD.new(options[:machines], options[:buffers])