require "./production"

class DVD < Production
  def action
    schedule(2.hours, "Entering store") do
      say("Add 3 apples to basket")
      say("Add 1 banana to basket")
      schedule(2.minutes, "Stand in queue") do
        say("Paying at counter")
        schedule(5.minutes, "Leaving store") do
          done!
        end
      end
    end
  end
end

DVD.new