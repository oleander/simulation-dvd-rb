class Filter < Struct.new(:items, :offset, :runtime)
  class R < Struct.new(:amount, :total_time)
    def average
      ((total_time / amount.to_f) / 60.0).round
    end
  end

  def process!
    start_time = items.first.done_at
    limit = start_time.to_i + offset * 60

    real_runtime = runtime.hours - offset * 60

    # Remove all items that is outside out scope
    items.select! { |item| item.done_at.to_i >= limit }

    a = items.inject({}) do |result, item|
      key = ((item.done_at.to_i - start_time.to_i) / (60.0)).round
      result[key] ||= R.new(0, 0)
      result[key].total_time += item.production_time
      result[key].amount += 1
      result
    end

    production = items.length / real_runtime.to_f
    thruput = items.map {|i| i.production_time }.inject(:+).to_f / items.length
    variance_thruput = items.map{|item| (item.production_time / (60 * 60) - thruput / (60 * 60))**2}.inject(:+) / (items.length - 1)
    variance_production = a.keys.map do |key| 
      b = a[key].total_time / (60 * 60)
      (b - production / (60 * 60))**2
    end.inject(:+) / (items.length - 1)

    return {
      production: (production * 60 * 60).round(2),
      thruput: (thruput / (60 * 60)).round(2),
      variance_thruput: variance_thruput.round(2),
      variance_production: variance_production.round(2),
      length: items.length
    }
  end
end