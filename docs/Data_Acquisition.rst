
#################
Data Acquisition
#################

**********
Overview
**********

This software surrounds hardware made with Intan RHD amplifier and digitization chips for electrophysiology:

http://intantech.com/

Which communicate with Opal Kelly FPGAs 

http://intantech.com/products_RHD2000_Rhythm.html

Opal Kelly provides the Rhythm interface as open source C++ and verilog code. This project seeks to be a Julia alternative to allow for easier integration of spike sorting and closed loop control in the Julia language. 

*********
Workflow
*********

The main control loop has the following steps

#. Read neural data from the Intan board.

The Intan board will continuous run throughout the experiment, capture and organize the digital neural signals coming from headstage, and keep them in RAM until the control computer brings them over. How frequently data is brought over from the FPGA board is set by the user, and the "best" frequency depends on the experimental setup (remember that this will not affect the sampling rate of the headstages). By default, Intan.jl pulls from the FPGA board once 600 samples from each channel have accumulated. At a 20kHz sample frequency, this will correspond to a latency of roughly 30 ms. 

The control loop must run faster than this minimum latency. Therefore, at the beginning of each loop iteration, the board is check to see if it has accumulated 600 samples. If not, it waits very briefly and then checks again. If it has, it pulls the data over to the PC. This will take a small amount of time due to overhead of the method of transfer, as well as the speed of transfer itself. Once the data is brought over, it must be parsed into a more sensible format, which is a 600 x channel matrix of 16 bit integers.

#. Spike Sorting

The new matrix of voltage data is then put through the spike sorting paradigm of the users choice. Any spikes that are detected and clustered will be stored in RAM for the following steps.

#. Task Logic

Intan.jl will now implement the user's task logic, which corresponds to the "do_task" function for the Task data structure. This may be nothing, such as with "Task_NoTask," or it may involve updating task GUIs (e.g. a center out cursor position), performing some calculation with the newly found spikes (e.g. brain machine interface decoding), controling external task-relevant equpiment (e.g. spike-triggered stimulation), etcetera.

#. Update Intan.jl GUI

Now the main GUI will be updated, with any newly identified spikes plotted.

#. Saving

Finally, the data from this loop iteration will be saved. This includes the neural data and whatever task data is specified in the "save_task" function (this could be nothing). Data is saved as a binary file for speed, which will then be parsed into a more useful HDF5 format immediately after the experiment is complete.

***************
Initialization
***************

First, the user should specify how the headstage is connected to the Intan Evaluation board. The evaluation board has 4 SPI ports, which each can recieve two headstages via a y connector. These headstages are therefore labeled A1,A2,B1,B2,C1,C2,D1,D2. The user must create an Amp data structure for each amplifying by specifying the port it is connected to and calling the function corresponding to the amplifying type. These are then provided to the RHD2000 function as an array. For example:

.. code-block:: julia 

	#96 channel setup with 64 channel amp and 32 channel amp connected to Port A with a y connector

	#64 channel amp connected to the A1 port
	myamp1=RHD2164("PortA1")

	#32 channel amp connected to the A2 port
	myamp2=RHD2132("PortA1")

	myrhd=RHD2000([myamp1,myamp2],"single",mytask)


.. code-block:: julia 

	#128 channel setup with 64 channel amps connected to ports A and B

	#64 channel amp connected to the A1 port
	myamp1=RHD2164("PortA1")

	#64 channel amp connected to the B2 port
	myamp2=RHD2164("PortB1")

	myrhd=RHD2000([myamp1,myamp2],"single",mytask)


Once the main RHD2000 data structure is created, the user can create the GUI with the makegui function.

.. code-block:: julia 

	#Creates the GUI
	handles = makegui(myrhd);

To connect to the board and perform initialization, click the Init button in the top left hand corner.

************
Calibration
************

The board will need to run for a few seconds before further processing to adequately calculate the thresholds for spike detection on each channel. So when the user clicks "Run", no signals will be displayed at first. This is becuase the "calibration" check box is checked. Once several seconds have passed, the user should uncheck the calibration box and neural signals will start to appear.

****************
Data Collection
****************

After calibration has finished, the full control loop will run until the "Run" button is unclicked.

