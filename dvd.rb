require "./production"

class DVD < Production
  def setup
    # Macine 1: im
    # Machine 2: dry
    # Machine 3: sputt, coat
    # Machine 4: print
    @machines = {
      im: 4,
      dry: 2,
      sputt: 2,
      coat: 2,
      print: 2
    }

    # Events
    #  start_machine_1
    #  machine_1_done

    #  start_machine_2
    #  machine_2_done

    #  machine_2_conveyor_belt

    #  start_sputtering_machine
    #  sputtering_machine_done

    #  start_coat_machine
    #  coat_machine_done

    #  start_conveyor_belt_for_coat
    #  conveyor_belt_for_coat_done

    #  start_machine_4
    #  machine_4_done

    #  machine_1_broke_down
    #  machine_1_fixed

    done_in(2.days) do
      say("We're now done!")
    end

    # -> machine_1_done
    def start_machine_1(_)
      
    end

    # --> start_machine_1
    # --> start_machine_2
    def machine_1_done(_)
      
    end

    # -> machine_2_done
    # --> start_machine_1
    def start_machine_2(_)
      
    end

    # --> start_machine_2
    # -> machine_2_conveyor_belt
    def machine_2_done(_)
      
    end

    # --> start_sputtering_machine
    def machine_2_conveyor_belt(_)
      
    end

    # -> sputtering_machine_done
    def start_sputtering_machine(_)
      
    end

    # --> start_sputtering_machine
    # --> start_coat_machine
    def sputtering_machine_done(_)
      
    end

    # -> coat_machine_done
    def start_coat_machine(_)
      
    end

    # --> start_coat_machine
    # --> start_conveyor_belt_for_coat
    def coat_machine_done(_)
      
    end

    # -> conveyor_belt_for_coat_done
    def start_conveyor_belt_for_coat(_)
      
    end

    # --> start_machine_4
    def conveyor_belt_for_coat_done(_)
      
    end

    # -> machine_4_done
    def start_machine_4(_)
      
    end

    # --> start_machine_4
    def machine_4_done(_)
      
    end

    # -> machine_1_fixed
    def machine_1_broke_down(_)
      
    end

    # -> machine_1_broke_down
    # --> start_machine_1
    def machine_1_fixed(_)
      
    end
  end
end

DVD.new