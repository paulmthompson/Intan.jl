
################
Getting Started
################

**********
Overview
**********

This software surrounds hardware made with Intan RHD amplifier and digitization chips for electrophysiology:

http://intantech.com/

Which communicate with Opal Kelly FPGAs 

http://intantech.com/products_RHD2000_Rhythm.html

Opal Kelly provides the Rhythm interface as open source C++ and verilog code. This project seeks to be a Julia alternative to allow for easier integration of spike sorting and closed loop control in the Julia language. 

Although you don't have to use spike sorting, the module assumes that you have the SpikeSorting.jl module on your computer:

https://github.com/paulmthompson/SpikeSorting.jl

*********
Workflow
*********




************
Quick Start
************

The RHD2000 data type will keep track of the specifics of your setup, such as the amplifiers, TTL logic, and DAQs that are connected to the FPGA. Amplifiers are their own type and can be initialized by specifying their location. We are assuming the Intan Evaluation board or OpenEphys setup, where there are 4 SPI ports, each which can be attached to a Y connector. Therefore, there are 8 possible locations: A1,A2,B1,B2,C1,C2,D1,D2. We can initialize the board then as follows:

.. code-block:: julia
	
	#Create Amplifier setup. Here we assume 1 64 channel connected at PortA1
	myamp=RHD2164("PortA1")


	
