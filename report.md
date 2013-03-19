## Report

### Implementation

#### Machine Groups
#### Machine
#### Buffer
#### Item

### Explain

- Reserve next buffer
- Machine and machine group

### Assumptions

We're made a few assumptions regardning the third machine. We've tried to make logical assumptions based on the information we got from the interview.

#### Sputtering

This part of the machine can handle one bantch à 20 items at the time. As soon as every item as been processed (20 * 10 seconds) the batch is being passed to the lacquer coating part. The coating machine can't crash nor stall, it's also faster than sputtering. This means that we lacquer coating must always be ready when sputtering is done.

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
    - If buffer #2 % 20 == 0
      - Event handler #7, sputtering machine done
      - Event handler #3, try to start dye coating machine group
  - Changes
    - If buffer #2 % 20 == 0
      - Decrement buffer #2 by 20
      - Reserve 20 items in buffer #2
      - Mark one machine in machine group as started
- #7 ()