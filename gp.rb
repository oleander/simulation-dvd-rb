require "gnuplot"

Gnuplot.open do |gp|
  Gnuplot::Plot.new( gp ) do |plot|

    plot.xrange "[-10:10]"
    plot.title  "Sin Wave Example"
    plot.ylabel "x"
    plot.xlabel "sin(x)"

    plot.data << Gnuplot::DataSet.new( "sin(x)" ) do |ds|
      ds.with = "lines"
      ds.linewidth = 4
    end
  end
end

# Gnuplot.open do |gp|
#   Gnuplot::Plot.new( gp ) do |plot|

#     plot.xrange "[-10:10]"
#     plot.title  "Sin Wave Example"
#     plot.ylabel "x"
#     plot.xlabel "sin(x)"

#     plot.data << Gnuplot::DataSet.new( "sin(x)" ) do |ds|
#       ds.with = "lines"
#       ds.linewidth = 4
#     end
#   end
# end


# Gnuplot.open do |gp|
#   Gnuplot::Plot.new( gp ) do |plot|
  
#     plot.title  "Array Plot Example"
#     plot.xlabel "x"
#     plot.ylabel "x^2"
    
#     x = (0..items.length).to_a
#     y = items.map(&:production_time)

#     plot.data << Gnuplot::DataSet.new( [x, y] ) do |ds|
#       ds.with = "linespoints"
#       ds.notitle
#     end
#   end
# end