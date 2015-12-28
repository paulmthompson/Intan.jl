
module Intan

using HDF5, DistributedArrays, SpikeSorting, Gtk.ShortNames, Cairo, MAT

export RHD2000, RHD2164, RHD2132,  makegui, Debug

include("rhd2000evalboard.jl")
include("rhd2000registers.jl")
include("constants.jl")
include("gui.jl")
include("plotting.jl")
include("offline.jl")

end
