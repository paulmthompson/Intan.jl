#=
This file demonstrates the framework of functions and data structures necessary to implement a task
=#

export Task_NoTask

#=
Data structure
should be a subtype of Task abstract type
=#

type Task_NoTask <: Task
end

#=
Constructors for data type
=#

#=
Initialization function
This will build all of the necessary elements before anything starts running
(initializing external boards, creating GUIs etc)
=#
function init_task(myt::Task_NoTask,rhd::RHD2000)
end

#=
Experimental Control Function

This will implement the control logic of the task
such as updating GUIs, modifying the data structure, talking to external boards
=#
function do_task(myt::Task_NoTask,rhd::RHD2000,myread)
end

#=
Logging Function

This will save the appropriate elements of the data structure, as well as specifying what 
analog streams from either the Intan or other external DAQs
=#
function save_task(myt::Task_NoTask,rhd::RHD2000)
end
