require "./production"

class DVD < Production
  def action
    schedule(2.hours, "Entering store") do
      schedule(2.minutes, "Stand in queue") do
        
        done!
      end
    end
  end
end

DVD.new