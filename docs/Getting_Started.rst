
################
Getting Started
################

*********
Overview
*********

This brief guide describes how to start the GUI, begin collecting extracellular electrophysiological data, and use some of the online spike sorting tools. Additional more comprehensive documentation can be found in later sections.

*****************
Connecting Intan
*****************

**************
Creating GUI
**************

Start the Julia terminal.Then load the Intan package:

.. code-block:: julia

	using Intan


The GUI can be started with the following line of code:

.. code-block:: julia

	Intan_GUI()


This will create a GUI with the default configuration file. The configuration file specifies how many evaluation boards and headstages are connected, what behavioral task is to be run, how data is to be saved, etc. The default assumes that a 64 channel RHD2164 headstage is connected to the Port A1 of the Intan Evaluation board.

These files are simple and typically only a few lines of code. The user can create their own and then load it passing the path to the file as an argument to Intan_GUI:

.. code-block:: julia

	Intan_GUI("/path/to/your/configuration/file.jl")


More documentation on designing the appropriate configuration can be found in its own section of this guide.

*******************
Interface Overview
*******************

Now the interface should appear. The GUI is divided into several regions by default:

.. image:: GUI.png


The far left pane contains the most commonly used buttons for online spike sorting and data visualization. This pane also contains the buttons that start the data acquisition at the top.

The upper left pane shows a magnified view of a single channel. By default this shows the snippet of voltage surrounding a threshold crossing. The slider to set that threshold crossing is located on the left hand side. In this view, waveforms assigned to particular clusters (single units) will be assigned different colors. 

The lower left pane shows spike sorting specific visualizations from the single channel highlighted above. These include the templates used for online template matching, and the color coded spike rasters for each individual unit.

The right pane is used for additional visualizations of incoming data. Some of these include 1) multiple channel displays, 2) multiple channel spike rasters, 3) digital oscilloscope and 4) digital events and analog signals from data given to the TTL and ADC inputs to the Intan evaluation board. One the right side of this pane are the buttons used to select which of these are displayed.

Finally, the top menubar has additional options, such as saving and loading sorting parameters, changing sorting options, and defining reference configurations.

*****************
Data Acquisition
*****************

The buttons used to start acquisition are located in the top right of the GUI. To begin data acquisition, first communication with the evaluation board and headstages must be established. This is done by clicking on the "Init" button. The output of the Julia terminal should indicate if the board is found and initialized correctly.

The "Run" button will begin acquisition with the evaluation board. After clicking the run button, the experimental timer should start climbing on the top right of the GUI. You will see that the "Calibrate button" is checked at this point, and data is not being displayed. At first, the data is being used by the software to start to find optimum threshold and sorting values. This calibration period only needs to last a second or so. To start data visualization, uncheck the "calibrate" box.


