
module Intan

using HDF5, DistributedArrays, SpikeSorting, Gtk.ShortNames, Cairo

export RHD2000, RHD2164, RHD2132, init_board, makegui

include("rhd2000evalboard.jl")
include("rhd2000registers.jl")
include("constants.jl")
include("gui.jl")
include("plotting.jl")

end
