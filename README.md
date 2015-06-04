# Intan RHD2000 Evaluation Board Interface

These modules are a Julia port of the Rhythm acquisition software that comes with Intan Technologies 
RHD2000-Series Amplifier Evaluation System for neural signal acquisition. 

# Files of Interest

The "Load_intan" IJulia notebook finds the Intan evaluation board, initializes it, calibrates the amplifiers,
and controls acquisition. This functions the same as the "main.cpp" file in the Rhythm API that comes with Intan.

The "rhd2000evalboard" module contains the functions for initializing the board and taking care of the data structures.
This module is a combination of the datablock and evalboard classes in the original API.

The "rhd2000registers" module generates the commands to be send from the eval board to the amplifiers.

# Required Modules

* HDF5 - https://github.com/timholy/HDF5.jl
* SpikeSorting - https://github.com/paulmthompson/SpikeSorting.jl

# How To Use

* Change the paths in the rhd2000evalboard.jl for the appropriate location of the Intan driver library, and the bit file. I did all of this on GNU/Linux, so there might be some problems if you need something other than a .so file.
* This code anticipates that you are using one RHD2164 64 channel amplifier connected to port A. Every additional 32 channels needs a new data stream defined, and 2 data streams can fit on one port. More instruction to come (I don't have another 64 channel amp to adequately test more streams right now).
* Plug in the Intan, and evaluate the cells in the Load_intan IJulia notebook. 
* Acquisition time can be adjusted by the setMaxTimeStep function, which by default is set to 20000 samples (1 second).
* The notebook will create a "test.jld" file in working directory that contains ~1 second of data in real time. Because 20000 is not a multiple of the smallest data block it will read (600), the actual length of data collected will not be exactly 20000 samples.

MANY more instructions and examples to come. In general it works very similar to the original C++ software, which has pretty good documentation here:

http://www.intantech.com/files/Intan_RHD2000_USB_FPGA_interface.pdf

The biggest change is probably the data structure was changed from a user defined class to a dictionary with keys for each variable, which is then saved as a HDF5 file. I thought this would be easier to work with, but I might be totally wrong.

# Current Functionality

* Able to find eval board
* Initializes board and lets you do cool things like turn on and off ports/LEDs/streams etc
* Able to acquire data in real time and save to HDF5 file

# To Do

## General

* Figure out how to incorporate into julia Pkg system
* Since I pretty much stuck to the form of the C++ code, there are a lot of areas where the syntax and methods can be made a lot simpler by taking advantage of some of Julia's built in functions. For instance, many of the functions in the registers module could probably be 2 lines instead of 20.
* The ccall that reads data from the Intan to the usb Buffer seems slow to me (~.001 seconds for a SAMPLES_PER_DATA_BLOCK size of 60). At 20000 samples per second, this wouldn't be fast enough to run in real time.  Fortunately, the speed of this doesn't scale linearly with the block size, so that making the block size larger (so you do it less and read more data) fixes the problem. Maybe the problem is that I'm allocated the array in Julia, and then filling it with a ccall, which probably operates in row-major order, but some tests don't seem to confirm this. Not really sure what to do about this.

## Spike Sorting
* I've been working on an unsupervised spike sorting routine based on many of the OSort algorithms. Right now it looks like Julia will allow this to run for many channels with enough speed to keep up with the data the Intan is throwing at it. Right now it is integrated, but need some bug fixes and additional testing. Also the spike sorting algorithm is completely bare bones and needs some more bells and whistles (as well as supervised control).

## DAQ
* I get the values from the intan but don't do anything with them. Arguments need to be added to indicate which DAQs are needed for an experiment, and functions need to be adjusted to write these to disk in real time like the electrode and time vectors.

## UI
* Add GUI elements, for both UI and experimental design (cursor on a screen controlled by a joystick etc). I've started looking at PyCall and MatplotLib for this, and it looks like they are pretty easy to use and fast enough. Still far from decided though.

## Parallel Processing
* Haven't done anything yet with parallel processing. Briefly looking at Julia makes it seem like it shouldn't be too hard to do, and with the Intan taking care of the time stamps and such I don't have to worry as much about how fast each thread is moving relative to the other. Probably will first start starting with Spike sorting.




## Validation
* Test with primate to see if real data is coming in through amplifiers

