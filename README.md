# Drone control in VHDL
## Overview
This repository contains VHDL project for a 2-wheels drone, which task is to use color detection sensors to navigate itself- following 
the black line. 

This project targets [Basys3 FPGA](https://digilent.com/reference/programmable-logic/basys-3/start?srsltid=AfmBOootJ_Xc5RPQhrUF_4EjSZz0n5AzfdAWLAsDfwucPtwLKkmuGbEX). This device is the driver for a 2-wheel drone, which is equipped with 
color detection sensors. These sensors are used to determine where is the black line that the drone has to follow. The black line defines
the path.

### Task description
The drone is initially in the ```IDLE``` state and is awaiting for a button press which sets it to ```RUNNING``` state. Since the 
button trigger drone begins to follow the black line which is underneath it- in case of no black line beneath the robot it pauses (awaiting in the ```RUNNING``` mode). As long as robot can detect the black line it follows it effectively performing loops according to the track geometry.

## Structure
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
Inside the Makefile user can specify paths to descirbed above directories. Provided Makefile contains an example how this could look like.
Furthermore, the name of the project, language and device have to be specified (currently only a single language per project is allowed).
Several directovies govern the workflow:
- ```make conf```: checks, if all direcotires exist and instantiates them in case some are missing
- ```make sim_all```: runs all availabele testbenches which are stored inside ```src/sim/```-> each tesbench will have a separate direcotry inside ```simulation/waveforms```
- ```make sim_sel TB="..."```: runs only selected (one or multiple) tesbenches and stores their results inside ```simulation/waveforms```. ***use quote marks to place multiple tesbenches, use only module names!***
- ```make bit```: generates bitstream and netlist which are stored respectively inside ```bin/bit``` and ```bin/netlist```
- ```make program_fpga```: programs an FPGA device according to ```device``` field from the Makefile
- ```make clean```: clears ```bin/``` and ```log/``` directories. ***its doesn't clear ```simulation/```***

In the root directory there is an imporant script which has to be included in any projects making us of this template- ```dep_analyzer.py```. It is responsible for gathering compile sources during executing ```sim_sel``` target for a specified testbench/testbenches and for them only. This solution speeds up compilation time as no longer all the sources compile for a single testbench (which might not even use it- yes, I know I well thought it at the beginning xd).

### First use
Run ```make conf``` to prepare missing directories which ```.gitignore``` skips or move on to any other directive except of ```clean``` as they rely on ```conf```.

## TODOs:
- multi-language support (allow mixed-language projects)
- support for non-commercial simulators like Verilator etc...
- add ```data``` dictionary from which some tesbenches could fetch data for simulations (subject of tests, if this is really an issue for this template)
- add tests results analysis tool
- add instruction how to integrate with CI/CD tools for cutting-edge automation
- modify ```dep_analyzer.py``` to group testbenches with their respective sources and potentially cache them so they don't get compiled multiple times