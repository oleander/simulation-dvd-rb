require "json"
require "hirb"

result = File.read("res.txt").split("----------------").map do |row|
  unless row.strip.empty?
    JSON.parse(row)
  end
end.reject(&:nil?)

result1 = result.sort_by do |sample|
  -1 * sample["production"]
end

result2 = result.sort_by do |sample|
  sample["thruput"]
end

class Container < Struct.new(:args)
  # {"machines":{"im":4,"dye":2,"sputt":2,"lac":2,"print":2},"buffers":[{"id":0,"ness":{"fullness":0.068,"emptyness":0.033},"current_size":17,"size":20},{"id":1,"ness":{"fullness":0.094,"emptyness":0.593},"current_size":16,"size":20},{"id":2,"ness":{"fullness":0.0,"emptyness":0.087},"current_size":0,"size":60},{"id":3,"ness":{"fullness":0.0,"emptyness":0.0},"current_size":3728,"size":null}],"runtime":96,"quiet":true,"production":40.6,"thruput":0.69,"variance_thruput":0.48,"variance_production":1.98}
  # def initialize(args)
      
  # end

  def buffers
    args["buffers"][0..-2].map do |buffer|
      buffer["ness"]["fullness"].to_s + "|" + 
      buffer["ness"]["emptyness"].to_s + "|" + 
      buffer["current_size"].to_s + "|" +
      buffer["size"].to_s
    end.join(" ?? ")
  end

  def thruput
    args["thruput"]
  end

  def production
    args["production"]
  end

  def variance_production
    args["variance_production"]
  end

  def variance_thruput
    args["variance_thruput"]
  end
end

result1.map! do |sample|
  Container.new(sample)
end

result2.map! do |sample|
  Container.new(sample)
end

extend Hirb::Console
Hirb.enable({pager: false})

table(result1, fields: [:buffers, :thruput, :production, :variance_production, :variance_thruput])