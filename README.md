[![Join the chat at https://gitter.im/Intan-jl/Lobby](https://badges.gitter.im/Intan-jl/Lobby.svg)](https://gitter.im/Intan-jl/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

# Intan.jl
# Intan RHD2000 Evaluation Board Interface

This is an electrophysiology interface that should be usable with any of the Intan acquisition systems, but it can be configured to be used with any acquisition system that allows you to stream the data to it (I stream a single channel amplifier to one of the ADC inputs of the Intan). 

The system includes a GUI for data visualization, online spike sorting, and control of the Intan evaluation board. There is also a component that allows you to design task-specific Julia code for running your experiments. I have used this make GUIs for experimental control (turning on TTLs for laser stimulation, juicer solenoid reward etc), behavioral visualization displays (like 3D environments in OpenGL or joystick controlled cursors), or for saving task specific streaming data (like high speed video for licking or whisker tracking).

<b>I think I am the only person who actually uses this, so God only knows if it works outside of my (clumsy) hands.</b> However, I have used it for electrophysiology exclusively for several years, and expect it can be used in other experimental setups with some adaptation.

# Installation

The package uses Julia version 0.6 (newer version compatibility coming soon!) and requires both Intan.jl and SpikeSorting.jl

Pkg.clone("https://github.com/paulmthompson/SpikeSorting.jl.git") <br>
Pkg.clone("https://github.com/paulmthompson/Intan.jl.git")

Right now this system is UNIX ONLY! :( It technically runs on Windows, but there is some weird GTK.jl package problem on Windows that makes all GUIs too slow for real time https://github.com/JuliaGraphics/Gtk.jl/issues/325. I would love for someone much smarter than me to solve this problem :)

# Documentation

http://intanjl.readthedocs.org/en/latest/

