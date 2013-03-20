## Report

### Implementation

#### Machine Groups
#### Machine
#### Buffer
#### Item

### Explain

- Reserve next buffer
- Machine and machine group
- Last buffer
- How events are initialized
- Insvängning

### Assumptions

We're made a few assumptions regardning the third machine. We've tried to make logical assumptions based on the information we got from the interview.

#### Sputtering

This part of the machine can handle one bantch à 20 items at the time. As soon as every item as been processed (20 * 10 seconds) the batch is being passed to the lacquer coating part. The coating machine can't crash nor stall, it's also faster than sputtering. This means that we lacquer coating must always be ready when sputtering is done.

- TODO: Explain items being stuck

#### Lacquer coating

This part does the same thing as the sputtering. It process 20 items in sequence each taking 6 seconds. As soon as all items are done the batch as whole is placed on the conveyor belt.

## Problem description

A DVD factory wants to optimize there production by keeping the ratio between system throughput, buffer size and the amount of machines has low as possible.

## Explanation of the models

### Events and event handlers

- Injection molding #1
- Dye coating #2

Note 1: All logic related to a machine is encapsulated in its own event handler. This means that this event might be called even tho the machine group it self isn't ready. So for example if machine #2 has started and therefor decresed buffer #1 by one (the buffer used by machine #1 and machine #2) it will, without checking the state of machine group #2, try to start #1 by calling event handler #1. This structure means that we can keep all logic for one machine group contained within one event handler.

Note 2: We've tried to do as few things as possible in one event handler, even if the outcome in some cases is an event handler that only acts as a proxy. One example is event handler #5. It only acts as a implementation proxy with the single purpose of reporting its current state and call event handler #6. An alternitive would be to call event handler #6 directly from #4. The drawback would be a bit more complicated event graph, which wouldn't benefit anyone.

- #1 (Start injection molding)
  - Tries to start injection molding machine
  - Schedules
    - if start was a success
      - Event handler #2
  - Changes
    - if start was a success
      - Reserves one item in buffer #1
      - Mark one machine in machine group #1 as started
      - Create item with initial time (time the item was created)
- #2 (injection molding done)
  - Injection molding is done
  - Schedules
    - Unless machine group #1 was or is broken
      - Restart/start machine group #1
      - Try to start machine group #2
  - Changes
    - Unless machine group #1 was or is broken
      - Mark machine as idle
      - Add item to buffer #1
- #3 (Start dye coating machine group)
  - Tries to start injection molding machine
  - Schedules
    - if start was a success
      - Event handler #4
  - Changes
    - If avalible machines > 0, previous buffer isn't empty and next buffer isn't full
      - Decrement previous buffer with one
      - Reserve one item in buffer #2
      - Mark one machine in group as taken
- #4 (Dye coating machine group done)
  - Dye coating machine group is done
  - Schedules
    - Restart/start machine group #2
    - Event handler #5, one new item on conveyor belt
  - Changes
    - Mark machine as idle
- #5 (Conveyor belt)
  - One item just fell of the conveyor belt
  - Schedules
    - Event handler #6, start sputtering machine group
  - Changes
    - Increment next buffer by one
    - Remove reservation on next buffer
- #6 (Try to start sputtering machine group)
  - Try to start sputtering machine group
  - Schedules
    - If buffer #2 % 20 == 0 and avalible machines > 0
      - Event handler #7, sputtering machine done
        - Take into acount that an
      - Event handler #3, try to start dye coating machine group
  - Changes
    - If buffer #2 % 20 == 0 and avalible machines > 0
      - Decrement buffer #2 by 20
      - Reserve 20 items in buffer #2
      - Mark one machine in machine group as started
- #7 (Sputtering machine done)
  - A sputtering machine is done
  - Schedules
    - Event handler #6, try to restart sputtering machine group
    - Event handler #8, start coating machine group
  - Changes
    - Mark done machine as idle
- #8 (Start coating machine group)
  - Start a coating machine. This machine will always be avalible and ready after the sputtering machine group is done
  - Schedules
    - Event handler #9, coating machine done
  - Changes
    - Nothing
- #9 (Coating machine done)
  - Coating machine is done
  - Schedules
    - Event handler #10, start conveyor belt #2
  - Changes
    - Nothing
- #10 (Start conveyor belt #2)
  - Conveyor belt #2 has started
  - Schedules
    - Event handler #11, one item just fell of conveyor belt #2
  - Changes
    - Nothing
- #11 (20 items just fell of conveyor belt #2)
  - 20 items just fell of conveyor belt #2
  - Schedules
    - 20 x event #12, try to start printing machine group
  - Changes
    - Increment buffer #3 by 20
    - Remove reservation (20 items) from buffer #2
- #12 (Trying to start printing machine group)
  - Trying to start printing machine group
  - Schedules
    - If avalible machines > 0 and buffer #3 isn't empty
      - Event #13, printing machine is done
      - Event #6, try to start sputtering machine
  - Changes
    - If avalible machines > 0 and buffer #3 isn't empty
      - Decrement buffer #3 by 1
      - Mark one machine in machine group as started
- #13 (Printing machine done)
  - Printing machine is done
  - Schedules
    - Event #12, try to restart printing machine group
  - Changes
    - Write end time to produced item
    - Add item to buffer #4 (output container)
    - Mark machine done as idle
- #14 (Injection molding machine just broke down)
  - Injection molding machine just broke down
  - Schedules
    - Event handle #15, machine was fixed
  - Changes
    - Mark machine as broken
- #15 (Injection molding machine is now fixed)
  - Injection molding machine is now fixed
  - Schedules
    - Event handle #1, try to start/restart injection molding machine
    - Event handle #14, injection molding machine just broke down
  - Changes
    - Mark machine as fixed. This will put the fixed machine in the idle state

### Warm up period to steady state

To ensure that the data that was used in our calculations didn't fluxuated (TODO: is this a word?), which is usuly the case in the begining of a simulation, we tried to, both graphically and mathematically determen where when the system became stable.

A parameter that nicely represents the current state of the system is the average production time of an item [min / item].

We did not have the CPU power to look at hundreds of samples for finding the warm up period. Instead of looked at the edge cases.

Clarification: The x-axis represents the elapsed time in minutes and the y-axis the average time in minutes for an item to pass through the system.

- Max buffers, minimum amount of machines

![1](resources/1.png)

- Max buffers, maximum amount of machines

![2](resources/2.png)

- Min buffers, minimum amount of machines

![3](resources/3.png)

- Min buffers, maximum amount of machines

![4](resources/4.png)

It looks like image #3 has the higest warm up period of 200 minutes. Adding an extra 50 minutes as a margin would keep us out of the warm range.

### Set up

To ensure the *best outcome be started by defining the upper and lower limits. The current configuration for system is as follow.

- Buffer capacities
  - #1 as a max capacity of 20
  - #2 as a max capacity of 20, by can only handle ha mutiple of 20
  - #3 as a max capacity of 20
- Amount of machines
  - Injection molding: 4
  - Dye coating: 2
  - Sputtering: 2
  - Lacquer coating: 2
  - Printing: 2

We call this set up the base line. This means that we won't go below any of the below numbers. 

The upper limits was a bit more tricky. Increasing base line to infinity capacity wouldn't make any sence, nor would it be realistic. Accordint to the interview a realistic upper limits for the buffers would be 100, 100 and 100, but nothing were specified for the machines.

According to our tests one simulation simulating 3 days took approximately 90 seconds using the base line.

Increasing each buffer by 20 up to a hundred would take 64 itterations. We then want to try to increase the amount of machines with one. This would result in a total of 2048 itterations, which would take approximately two and a half day to run.