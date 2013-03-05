require "./production"

class DVD < Production
  def init
    say("Opening store")
  end

  def action
    schedule(3.hours, "Buy new car", "a", "b", "c", :buy_new_car)
    schedule(5.hours, "Sell bad car") do
      done!
    end
  end

  def buy_new_car(a,b,c)
    say("Hello!")
  end
end

DVD.new