Intan RHD2000 Evaluation Board Interface
========================================

These modules are a Julia port of the Rhythm acquisition software that comes with Intan Technologies 
RHD2000-Series Amplifier Evaluation System for neural signal acquisition. 

Files of Interest
=================
The "Load_intan" IJulia notebook finds the Intan evaluation board, initializes it, calibrates the amplifiers,
and controls acquisition. This functions the same as the "main.cpp" file in the Rhythm API that comes with Intan.

The "rhd2000evalboard" module contains the functions for initializing the board and taking care of the data structures.
This module is a combination of the datablock and evalboard classes in the original API.

The "rhd2000registers" module generates the commands to be send from the eval board to the amplifiers.

Required Modules
================

* HDF5 - https://github.com/timholy/HDF5.jl

How To Use
==========

* Change the paths in the rhd2000evalboard.jl for the appropriate location of the Intan driver library, and the bit file. I did all of this on GNU/Linux, so there might be some problems if you need something other than a .so file.
* This code anticipates that you are using one RHD2164 64 channel amplifier connected to port A. Every additional 32 channels needs a new data stream defined, and 2 data streams can fit on one port. More instruction to come (I don't have another 64 channel amp to adequately test more streams right now).
* Plug in the Intan, and evaluate the cells in the Load_intan IJulia notebook. 
* Acquisition time can be adjusted by the setMaxTimeStep function, which by default is set to 20000 samples (1 second).
* The notebook will create a "test.jld" file in working directory that contains ~1 second of data in real time. Because 20000 is not a multiple of the smallest data block it will read (600), the actual length of data collected will not be exactly 20000 samples.

MANY more instructions and examples to come. In general it works very similar to the original C++ software, which has pretty good documentation here:

http://www.intantech.com/files/Intan_RHD2000_USB_FPGA_interface.pdf

The biggest change is probably the data structure was changed from a user defined class to a dictionary with keys for each variable, which is then saved as a HDF5 file. I thought this would be easier to work with, but I might be totally wrong.

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
* The ccall that reads data from the Intan to the usb Buffer seems slow to me (~.001 seconds for a SAMPLES_PER_DATA_BLOCK size of 60). At 20000 samples per second, this wouldn't be fast enough to run in real time.  Fortunately, the speed of this doesn't scale linearly with the block size, so that making the block size larger (so you do it less and read more data) fixes the problem. I'm not sure why I can't use the original block size of 60 however and think something must be wrong.
* Add spike sorting during acquisition loop, and save time stamps instead of 20000 samples/s of voltage. Will most likely convert algorithms from an open source matlab toolkit like Wave_clus, klustakwik, or OSort.
* Add DAQ functionality
* Add GUI elements, for both UI and experimental design (cursor on a screen controlled by a joystick etc). I'm happy to stay away from these for as long as possible, and I'm still very unsure of what avenue to take. I'm most familiar with Qt for graphics stuff, but most of my motivation for this project is to have a setup in one, easy to use language. Having a Julia to Pyside to Qt workflow, while it may work great, would be something I'd like to avoid if possible because it would just have so many moving parts. I'm not super familiar with notebook files, and I have been really impressed since my move to Julia. I have seen some pretty amazing modules like Interact that might do everything I need in a browser, but I'm really not sure because I'm so new. I imagine this may have pretty inconsistent speeds, but since the Intan does all of the timestamping with an onboard clock, that may not be as much of a problem as it would be with other setups.
* Figure out how to incorporate into julia Pkg system one day
* Since I pretty much stuck to the form of the C++ code, there are a lot of areas where the syntax and methods can be made a lot simpler by taking advantage of some of Julia's built in functions. For instance, many of the functions in the registers module could probably be 2 lines instead of 20.
* Find the many bugs and mistakes I have most certainly made in existing code. I'm a new Julia convert, so I'm also almost certainly not fully taking advantage of its speed in many places.



