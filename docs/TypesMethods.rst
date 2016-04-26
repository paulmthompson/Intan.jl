
##################
Types and Methods
##################

***************
Initialization
***************

.. function:: RHD2164(portstring)

   Returns data needed by evaluation board needed to recognize 64 channel amp connected to port specified in portstring

.. function:: RHD2132(portstring)
	
   Returns data needed by evaluation board needed to recognize 32 channel amp connected to port specified in portstring

.. function:: RHD2000(myamps,processor,mytask)

.. function:: makegui(rhd)

********************
Experimental Control
********************

.. function:: init_task(mytask,rhd)

.. function:: do_task(mytask,rhd)

.. function:: save_task(mytask,rhd)
