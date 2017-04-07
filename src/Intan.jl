
module Intan

using HDF5, DistributedArrays, SpikeSorting, Gtk.ShortNames, Cairo, MAT,JLD

import SpikeSorting.Vec2, SpikeSorting.RubberBand, SpikeSorting.rb_set, SpikeSorting.rb_draw, SpikeSorting.identity_matrix, SpikeSorting.select_color

export makeRHD, RHD2164, RHD2132,  makegui, Debug, Intan_GUI

include("types.jl")
include("constants.jl")
include("gtk_helpers.jl")
include("rhd2000evalboard.jl")
include("rhd2000registers.jl")
include("gui.jl")
include("plotting.jl")
include("offline.jl")
include("filters.jl")
include("task_list.jl")
include("save_load.jl")
include("benchmark.jl")
include("wifi.jl")

#Spike Sorting
include("sorting/windows.jl")
include("sorting/templates.jl")

#Graphics
include("graphics_help/cairo.jl")

end
