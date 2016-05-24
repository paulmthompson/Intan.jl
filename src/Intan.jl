
module Intan

using HDF5, DistributedArrays, SpikeSorting, Gtk.ShortNames, Cairo, MAT,JLD, DSP

export makeRHD, RHD2164, RHD2132,  makegui, Debug

include("types.jl")
include("constants.jl")
include("rhd2000evalboard.jl")
include("rhd2000registers.jl")
include("gui.jl")
include("plotting.jl")
include("offline.jl")
include("filters.jl")
include("task_list.jl")
include("save_load.jl")
include("benchmark.jl")

#Graphics
include("graphics_help/cairo.jl")

end
