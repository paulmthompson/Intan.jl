
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

*******************
Initializing Board
*******************

The RHD2000 data type will keep track of the specifics of your setup, such as the amplifiers, TTL logic, and DAQs that are connected to the FPGA. It is initialized as follows:



