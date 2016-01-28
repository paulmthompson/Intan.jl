
####
GUI
####

*********
Overview
*********

A simple GUI is under development that will control 1) data acquisition, 2) visualization, 3) automatic and manual spike sorting, and 4) experimental control.

.. image:: GUI.png

**************
Creating GUI
**************

The GUI can easily be created from an IJulia notebook. The user must specify which amplifiers are connected to which ports, and whether single or multi core processing is to be used. These are used to create an RHD2000 data structure, which is then used to construct the GUI. For example:

.. code-block:: julia 

	#First create amplifier array:
	myamp=RHD2164("PortA1")

	#Initialize evaluation board setup
	myrhd=RHD2000(myamp,"single");

	handles = makegui(myrhd);


*****************
Data Acquisition
*****************

===================
Connecting to Intan
===================

The "Init" button will connect to the Intan board. The output should indicate if the board is found and initialized correctly.

The "Run" button will begin acquisition with the evaluation board. The "calibration" button will be checked by default. As long as this is checked, detection thresholds will first be calculated, followed by any values that need calibrated for feature extraction, dimensionality reduction, or clustering. Unchecking the calibration button will cause normal data acquisition to start.

**************
Visualization
**************

There are two main canvases: the left canvas is a zoomed in view of one channel, while the right canvas shows 16 channels at a time. Each spike that was detected and clustered will be plotted to these canvases in real time.

The slider underneath the left canvas selects which of the 16 channels from the right canvas will be displayed. The slider underneath the right canvas selects which group of 16 channels from the total channel count will be displayed.

The slider to the right of the left canvas adjusts the scaling of the channel of interest in both the left canvas and right canvas. This only effects plotting, but not sorting.

**************
Spike Sorting
**************

Sorted spikes are plotted in the canvases with their colors indicating the cluster they are assigned to.

=======
Manual
=======

=========
Automatic
=========

Intan.jl is integrated with the SpikeSorting.jl package for automatic spike sorting of multi-channel recordings.

********************
Experimental Control
********************
