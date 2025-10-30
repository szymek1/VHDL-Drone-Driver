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
The source code for the drone is entirely done in VHDL. 

Its comoponents are separated in the two principal packages:

- ```drone_utils_pkg```: contains generic IPs (```pwm_generic```, ```clk_divider_generic```, ```edge_detector```) used to directly interact with the hardware and electric motors
- ```screen_utils_pgq```: ***TODO***

The application logic is controller by two state machines: 

- ```main_FSM```: decides when the robot starts and stops according to the push of the button
- ```movement_FSM```: while the robot is allowed to move it responds to black line sensors to determine th epath which follows the line

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