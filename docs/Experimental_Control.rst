####################
Experimental Control
####################

*********
Overview
*********

This package can be used as part of an experimental workflow to record inputs and outputs, trigger events such as the start of a trial, or draw and manipulate what is seen on a computer screen. Every unique version of an experiment can be defined in a task file, which will create the data structures and methods necessary. Here we will outline some of the supported features for task creation.

**********************************
Basic Data Structures and Methods
**********************************

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

	function do_task(myt::Task_NoTask,rhd::RHD2000,myread)
	end

The "myread" variable is a boolean that indicates if data was read from the Intan board or not. If you only want your experimental control to run every time new data is acquired (for instance every 20 ms when sampling at 30khz), then place your methods inside a conditional myread==true block of code.

=================
Logging Function
=================

The "save_task" function will save the appropriate elements of the data structure, as well as specifying what analog streams from either the Intan or other external DAQs.

.. code-block:: julia 

	function save_task(myt::Task_NoTask,rhd::RHD2000)
	end


*********
Graphics
*********

======
Cairo
======

=======
OpenGL
=======

*************
Control Flow
*************
