# Drone control in VHDL
## Overview
This repository contains VHDL project for a 2-wheels drone, which task is to use color detection sensors to navigate itself- following 
the black line. 

This project targets [Basys3 FPGA](https://digilent.com/reference/programmable-logic/basys-3/start?srsltid=AfmBOootJ_Xc5RPQhrUF_4EjSZz0n5AzfdAWLAsDfwucPtwLKkmuGbEX). This device is the driver for a 2-wheel drone, which is equipped with 
color detection sensors. These sensors are used to determine where is the black line that the drone has to follow. The black line defines
the path.

### Task description
The drone is initially in the ```IDLE``` state and is awaiting for a button press which sets it to ```RUNNING``` state. Since the 
button trigger drone begins to follow the black line which is underneath it- in case of no black line beneath the robot it pauses (awaiting in the ```RUNNING``` mode). As long as robot can detect the black line it follows it effectively performing loops according to the track geometry. The second button press returns drone to the ```IDLE``` state. Moreover the robot is equipped with a simple screen (check Basys3 documentation), which displays robot's current speed.

### Architecture
The source code for the drone is entirely done in VHDL. The diagram below presents relations between modules.

![system_diagram](docs/system_diagram.drawio.svg)

System's comoponents are separated in three principal packages:

- ```control_pkq```: contains two FSMs which control movement of the drone
- ```drone_utils_pkg```: contains generic IPs (```pwm```, ```edge_detector```, ```btn_debouncer```) used to directly interact with the hardware and electric motors
- ```screen_utils_pkq```: ***TODO***

The application logic is controller by two state machines: 

- ```start_stop_FSM```: decides when the robot starts and stops according to the push of the button
- ```movement_FSM```: while the robot is allowed to move it responds to black line sensors to determine th epath which follows the line

#### Control Package
##### Start/Stop FSM
Start/Stop FSM responds to ```btn_pressed``` trigger signal by switching between two states:

- ```IDLE```
- ```RUNNING```

Signal ```i_btn_pressed``` is the output of ```edge_detector```. State ```RUNNING``` activates ```movement_FSM``` to leave its ```IDLE``` state.

![start_stop_FMS_diagram](docs/start_stop_FSM.drawio.svg)

##### Movment FSM
The idea behind following the path of the black line is to keep that line centrally underneath the drone. As already mentioned the drone has two sensors, which indicate when the black color is detected- this indicates a turn. When both sensors indicate 0 this means the robot is exactly underneath the line. This FSM controls the movement of the drone with four states:

- ```IDLE```: robot remains in place awaiting for ```i_is_running``` signal from ```start_stop_FSM```
- ```FORWARD```: robot is moving forward when both sensors indicate 0; 50% of power to the engines
- ```T_LEFT```: robot is turning to the left; right engine receives 15%, left engine receives 90% of power
- ```T_RIGHT```: robot is turning to the right; right engine receives 90%, left engine receives 15% of power

![movment_FMS_diagram](docs/movement_FSM.drawio.svg)

This FSM doesn't have any knowledge regarding the ```pwm``` parameters. It outputs a custom ```t_pwm_duty_cycle``` (defined inside ```control_pkg```), which gets interpretted into an actual duty cycle values inside ```drone_top```. Thanks to that ```movement_FSM``` and ```pwm``` are decoupled.

User can customize, if provided sensors indicate the black line as either logical 0 or 1.

```vhdl
generic (
        G_BLACK_LINE: std_logic := '1' -- specify the value which color sensors
                                       -- provide when the black color is detected.
                                       -- logic 1 by default 
    );
```

#### Drone Utilities Package
##### Button Debouncer
```btn_debouncer``` is the very first element in the chain of modules responsible for running the drone. Its task is to perform two activities:

1. Apply double flip-flop approach to mitigate the potential metastability when user presses the start button
2. Debounce the button- make sure that the signal triggered by the pressed button is long enough that it can be passed to the edge detection without casuing false triggers to the system

When the button is pressed it secures with the double flip-flop approach the stable signal. When the signal indicates that the button has been pressed it proceeds the count down for the specified duration and then checks again for the value of it, if the button indicates logical 1 when the counter is 0, then the triggering signal is sent to the ```edge_detector```.

This module allows for customization in terms of the necessary time for a stable button press and the main clock frequency.

```vhdl
generic (
        G_DEBOUNCE_TIMEOUT_MS: positive := 20;         -- button debounce time delay (by default 20ms)
        G_CLK_FREQ_HZ        : positive := 100_000_000 -- for this project it is assumed 100MHz
    );
```

##### Edge Detector
```edge_detector``` is responsible for determining, if the button was pressed by evaluating the rising/falling edge of the input signal ```i_signal```. This module assumes that the ```i_signal``` is stable, and this is guaranteed by ```btn_debouncer```. It determines rising/falling edge by initially assigning ```i_signal``` to ```s_prev_i_signal``` and then comparing two signals.

This module allows for customization in terms of rising/falling edge detection.

```vhdl
generic (
        G_RISING_EDGE: boolean := true -- detect rising edge by default
    );
```

##### PWM
```pwm``` generates actual steering signal to an electric motor. In the ```drone_top``` module one ```pwm``` module is instantiated per motor.

This implementation is based on the two counters approach. The first counter, defined as an internal signal- ```clk_cnt```, is used to derive lower frequency control signal for the ```pwm_process```. Given we wish to have PWM module operating in 5kHz frequency and the main clock is 100MHz we need to perform the following calculations:

```
100MHz/5kHz=20000 -> full PWM counting defined by resolution of G_PWM_BITS
                     must take 20000 cycles of 100MHz clock

20000/lenght(G_PWM_BITS = 256)=78 -> signle PWM counter step (o_pwm_cnt) happens
                                     every 78 100MHz clock cycles
```

The logic which decides when ```o_pwm_cnt``` increments and when PWM issues an impulse happens (as for the example above) every 78 100MHz clock cycles.

Customization is done via the generic map.

```vhdl
generic (
        G_PWM_BITS: integer;        -- specifies the resolution
                                    -- if equal to 8 bits the PWM counter will
                                    -- count from 0 to 255

        G_CLK_DIV : positive := 78  -- clock divider, it specifies how many
                                    -- "fast clk ticks" equal one "slow clk tick"
                                    -- set by default to the value allowing to 
                                    -- create 5kHz signal from 100MHz clock
    );
```

#### Top module
```drone_top``` unifies all the packages into the final design. Its important element is the ```p_pwm_decoder```, which interprets ```movement_FMS``` instructions (provided via signals: ```s_fsm_cmd_left```, ```s_fsm_cmd_right```) into an actual duty cycle, which is then provided to ```pwm``` modules.

```vhdl
-- Decoding FSM commands and generating the final PWM signal
    p_pwm_decoder : process (s_fsm_cmd_left, s_fsm_cmd_right) is
    begin
        -- left motor command
        case s_fsm_cmd_left is
            when DUTY_CYCLE_0   => s_pwm_duty_left <= C_DUTY_0_PCNT;
            when DUTY_CYCLE_15  => s_pwm_duty_left <= C_DUTY_15_PCNT;
            when DUTY_CYCLE_50  => s_pwm_duty_left <= C_DUTY_50_PCNT;
            when DUTY_CYCLE_90  => s_pwm_duty_left <= C_DUTY_90_PCNT;
        end case;
        
        -- right motor command
        case s_fsm_cmd_right is
            when DUTY_CYCLE_0   => s_pwm_duty_right <= C_DUTY_0_PCNT;
            when DUTY_CYCLE_15  => s_pwm_duty_right <= C_DUTY_15_PCNT;
            when DUTY_CYCLE_50  => s_pwm_duty_right <= C_DUTY_50_PCNT;
            when DUTY_CYCLE_90  => s_pwm_duty_right <= C_DUTY_90_PCNT;
        end case;
    end process p_pwm_decoder;
```


## Project's Structure
The project follows the structure derived from [this project of mine](https://github.com/szymek1/FPGA-TCL-Makefile-template).
```
.
├── bin
├── log
├── Makefile
├── dep_analyzer.py
├── scripts
│   ├── build.tcl
│   ├── program_board.tcl
│   └── simulate.tcl
├── simulation
│   └── waveforms
└── src
    ├── constraints
    │   └── constraints.xdc
    ├── hdl
    │   └── top.v
    └── sim
        ├── top_tb.v 
```
- ```bin/```: stores compiled bitstream and netlists
- ```log/```: stores logs produced by each of TCL scripts
- ```scripts/```: stores TCL scripts called from Makefile
- ```simulation/```: stores simulation results and logs per run testbench
- ```src/```: stores HDL and tesbenches source code as well as constraint file

There is one main Makefile specyfying all the targets and the target platform.

## Usage
For detailed build environment instruction please refer to [this project of mine](https://github.com/szymek1/FPGA-TCL-Makefile-template).

The key component is the Makefile from the root directory. The following targets can executed:

 ```make conf```: checks, if all direcotires exist and instantiates them in case some are missing
- ```make sim_all```: runs all availabele testbenches which are stored inside ```src/sim/```-> each tesbench will have a separate direcotry inside ```simulation/waveforms```
- ```make sim_sel TB="..."```: runs only selected (one or multiple) tesbenches and stores their results inside ```simulation/waveforms```. ***use quote marks to place multiple tesbenches, use only module names!***
- ```make bit```: generates bitstream and netlist which are stored respectively inside ```bin/bit``` and ```bin/netlist```
- ```make program_fpga```: programs an FPGA device according to ```device``` field from the Makefile
- ```make clean```: clears ```bin/``` and ```log/``` directories. ***its doesn't clear ```simulation/```***