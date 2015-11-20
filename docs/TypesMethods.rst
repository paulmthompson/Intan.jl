
##################
Types and Methods
##################

******
Types
******

=================
Evaluation Board
=================

This is the main interface for an Intan evaluation board. This is being designed with the Intan evaluation board in mind, but should work with OpenEphys board as well. 

--------
RHD2000
--------

Rather than calling this type directly, it is constructed through the "init_board" function, where the user specifies 1) the amps attached 2) the sampling rate 3) whether parallel/single core spike sorting should be used and 4) what spike sorting algorithm should be used. This constructs a type of the following form:

.. code-block:: julia

	type RHD2000{T<:Amp,V}
    		board::Ptr{Void} #Pointer to board identity in memory. Used for all communication with board
    		sampleRate::Int64 #Sampling rate in Hertz
    		numDataStreams::Int64 #Number of data streams out of possible 8
    		dataStreamEnabled::Array{Int64,2} #length 8 Row vector specifying with either 1 or 0 which data streams are enabled
    		usbBuffer::Array{UInt8,1} #Array that is filled with timestamps and amplifier channel voltages by communication with Intan
    		numWords::Int64 #Size of information coming through data streams
    		numBytesPerBlock::Int64 #Size of information coming through data streams
    		amps::Array{T,1} #All amps attached to evaluation board through SPI interface
    		v::AbstractArray{Int64,2} m x n voltage vector with m samples and n channels to contain voltages read from amplifiers
    		s::AbstractArray{V,1} # n length vector to contain spike sorting types for each channel
	end

===========
Headstages
===========

To initialize headstages, the user needs to specify the SPI port that the headstage is plugged into, from one of 8 possibilities: Port A1,A2,B1,B2,C1,C2,D1, or D2. The constructor will convert this into an integer value that the evaluation board will recognize

.. code-block:: julia
	
	#Create Amplifier setup. Here we assume 1 64 channel connected at PortA1
	myamp=RHD2164("PortA1")

========
RHD2164
========

This is the wrapper for a 64 channel Intan headstage. The user should be aware that the extra 32 channels from this amplifier are communicated in the same SPI port using a Double Data Rate (DDR) Multiplexer. The documentation explains this well:

http://www.intantech.com/files/Intan_RHD2164_datasheet.pdf

========
RHD2132
========

This is the wrapper for a 32 channel Intan headstage. 

********
Methods
********

===========
init_board
===========
