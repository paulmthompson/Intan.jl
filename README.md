Intan RHD2000 Evaluation Board Interface
========================================

These modules are a Julia port of the Rhythm acquisition software that comes with Intan Technologies 
RHD2000-Series Amplifier Evaluation System for neural signal acquisition. 

How to Use
==========
The "Load_intan" IJulia notebook finds the Intan evaluation board, initializes it, calibrates the amplifiers,
and controls acquisition. This functions the same as the "main.cpp" file in the Rhythm API that comes with Intan.

The "rhd2000evalboard" module contains the functions for initializing the board and taking care of the data structures.
This module is a combination of the datablock and evalboard classes in the original API.

The "rhd2000registers" module generates the commands to be send from the eval board to the amplifiers.

Current Functionality
=====================
* Able to find eval board
* Initializes board and lets you do cool thing like turn on and off ports/LEDs/streams etc
* Able to acquire data in real time and save to HDF5 file

To Do
=====
* Clean up random testing slop in notebook and unnecessary exported functions
* Test with primate to see if real data is coming in through amplifiers
* Change module to work with amps other than 64 channels
* Reading data from board to USB seems slow to me? making buffer size larger (so you do it less) is a temporary fix
* Add spike sorting during acquisition loop, and save time stamps instead of 20000 samples/s of voltage
* Add DAQ functionality
* Figure out how to incorporate into julia Pkg system one day
* Find the many bugs and mistakes I have most certainly made in existing code



