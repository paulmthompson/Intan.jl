##############
Spike Sorting
##############

*********
Overview
*********

Determing which pieces of a voltage vs time signal recorded from an extracellular electrode is attributable to an action potential fired by a neurby neuron is known as spike sorting. Spike sorting can be thought to consistent of several steps including 1) detecting candidate spikes, 2) aligning candidate spikes so they exist in the same relative time window, 3) transforming voltage vs time series of data points into some meaningful feature space, 4) reducing the high dimensional time series into a set of dimensions that can best discriminate electrical activity from one nearby neuron from another, and 5) clustering spikes with similar features to attribute them as arising from the same neuron.

This package makes available all of the spike sorting routines in the julia spike sorting package:

https://github.com/paulmthompson/SpikeSorting.jl

As well as additional manual manipulation of clusters that are automatically determined.

Note that the entire analog trace from each channel can also be saved for later offline sorting.

******************
Automatic sorting
******************

***************
Manual Sorting
***************

Spike clusters can be selected manually. For each channel, a cluster can be specified with a series of lines. A spike that crosses those lines will be assigned to that cluster. A new line for the selected cluster can be specified by left clicking, moving and releases. Right click allows the user to cycle through the lines of each cluster. Middle click clicks through clusters.
