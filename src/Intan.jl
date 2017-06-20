
module Intan

using HDF5, DistributedArrays, SpikeSorting, Gtk.ShortNames, Cairo, MAT,JLD, DSP

import SpikeSorting.Vec2, SpikeSorting.RubberBand, SpikeSorting.rb_set, SpikeSorting.rb_draw, SpikeSorting.identity_matrix, SpikeSorting.select_color

export makeRHD, RHD2164, RHD2132,  makegui, Debug, Intan_GUI

typealias MyFilter DSP.Filters.DF2TFilter{DSP.Filters.SecondOrderSections{Float64,Float64},Array{Float64,2}}

include("types.jl")
include("constants.jl")
include("gtk_helpers.jl")
include("gui/single_channel_canvas.jl")
include("gui/cluster_treeview.jl")
include("gui/multi_canvas_selection.jl")
include("gui/soft_scope.jl")
include("rhd2000evalboard.jl")
include("rhd2000registers.jl")
include("gui.jl")
include("plotting.jl")
include("offline.jl")
include("filters.jl")
include("task_list.jl")
include("save_load.jl")
include("benchmark.jl")

#Spike Sorting
include("sorting/windows.jl")
include("sorting/templates.jl")

#Graphics
include("graphics_help/cairo.jl")

end
