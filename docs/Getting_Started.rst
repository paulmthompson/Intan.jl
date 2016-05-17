
################
Getting Started
################

*********
Overview
*********

A simple GUI is under development that will control 1) data acquisition, 2) visualization, 3) automatic and manual spike sorting, and 4) experimental control.

.. image:: GUI.png

**************
Creating GUI
**************

The GUI can easily be created from an IJulia notebook. The user must specify 1) which amplifiers are connected to which ports, 2) what experimental control paradigm will be used, 3) how data should be saved and 4) if the GUI should be run in debug mode. These are used to create an RHD2000 data structure, which is then used to construct the GUI. Every initialization requires the amp structure, processing option, and task file. Everything else is given as keywords. For example:

.. code-block:: julia 

	#First create amplifier array:
	myamp=RHD2164("PortA1")

	#Assign amplifiers to FPGA:
	fpga_id=1
	myfpga=FPGA(fpga_id,myamp)

	#Specify a task file (NoTask is a valid option)
	mt=Task_NoTask()

	#Specifiy how neural data will be saved (Save nothing, spike shapes or entire recording)
	#mys=SaveAll()

	#Initialize evaluation board setup
	myrhd=RHD2000([myfpga],"single",mt, sav=mys)

	#Creates the GUI
	handles = makegui(myrhd);


*****************
Data Acquisition
*****************

===================
Connecting to Intan
===================

The "Init" button will connect to the Intan board. The output should indicate if the board is found and initialized correctly. The board still needs to be initialized in debug mode.

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

Spike clusters can be selected manually. For each channel, a cluster can be specified with a series of lines. A spike that crosses those lines will be assigned to that cluster. A new line for the selected cluster can be specified by left clicking, moving and releases. Right click allows the user to cycle through the lines of each cluster. Middle click clicks through clusters.

=========
Automatic
=========

Intan.jl is integrated with the SpikeSorting.jl package for automatic spike sorting of multi-channel recordings. None of the automatic methods currently allow for any manual manipulation.

********************
Experimental Control
********************

Intan.jl can also be used for experimental control, such as what is displayed in a separate GUI, closed loop control of stimulation, or real time processing of incoming signals. The Task_NoTask datastructure can be used when just pure recording is needed. User defined tasks can be created and must have the following components.

====================
Task Data Structure
====================

Every task will need its own data structure to store whatever variables are necessary for processing during the task. This should also store whatever additional variables besides neural signals that need to be logged. 

.. code-block:: julia 

	type Task_NoTask <: Task
	end

===============
Initialization
===============

An "init_task" initialization function will build all necessary elements before anything starts running (external boards, creating GUIs etc).

.. code-block:: julia 

	function init_task(myt::Task_NoTask,rhd::RHD2000)
	end

====================
Experimental Control
====================

The "do_task" function will implement the control logic of the task such as updating GUIs, modifying the data structure, talking to external boards. It is called immediately after spike sorting and before logging.

.. code-block:: julia 

	function do_task(myt::Task_NoTask,rhd::RHD2000)
	end

=================
Logging Function
=================

The "save_task" function will save the appropriate elements of the data structure, as well as specifying what analog streams from either the Intan or other external DAQs.

.. code-block:: julia 

	function save_task(myt::Task_NoTask,rhd::RHD2000)
	end


