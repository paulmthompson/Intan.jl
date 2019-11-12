
Installation Overview
=====================

Intan.jl is built using the Julia Programming Language. Additionally, Julia will call functions in several 
several C and Python libraries. In general, Julia's package manager is pretty good at taking care of these dependencies.

Right now, while Intan.jl is technically cross platform and built entirely from cross platform libraries, the GUI
library (Gtk) is much more slugglish on Windows, and consequently would not currently be suitable for real-time
processing. Hopefully soon these defects will be resolved.
