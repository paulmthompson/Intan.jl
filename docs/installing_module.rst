
Installing Intan.jl
====================

Launch a julia terminal. Julia packages are installed using functions in the package manager. For instance, to install
Gtk, the command would be simply "Pkg.add("Gtk")"

The "add" command will work with all registered packages, and should take care of all package dependencies. On Linux,
sometimes the underlying libraries must be installed separately using "sudo apt-get install package-name" in the
terminal. These packages are called the following on Ubuntu/Debian:

libgtk-3-dev
libhdf5-serial-dev

If you are using the RHD2000 acquisition board from Intan, you will also need to install the drivers necessary to
recognize the board, located on the Intan website:

intantech.com/downloads.html

Finally, sometimes on ubuntu, there will be some problems with the udev library being used by Intan and available in
the current release. If you experience problems, you may need to simlink the library it wants and the library you have
with this command:

sudo ln -sf /lib/x86_64-gnu/libudev.so.1 /lib/x86_64-linux-gnu/libudev.so.0
