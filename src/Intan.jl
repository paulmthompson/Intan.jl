__precompile__()

module Intan

using HDF5, DistributedArrays, SpikeSorting, Gtk.ShortNames, Cairo, MAT,JLD, DSP

import SpikeSorting.Vec2, SpikeSorting.RubberBand, SpikeSorting.rb_set, SpikeSorting.rb_draw, SpikeSorting.identity_matrix, SpikeSorting.select_color

if VERSION > v"0.7-"
    using SharedArrays, Libdl, Distributed, Dates
    const Void = Nothing
    const is_linux() = Sys.islinux()
    const is_apple() = Sys.isapple()
    const is_windows() = Sys.iswindows()
    const is_unix() = Sys.isunix()
    const setproperty! = set_gtk_property!
    const getproperty = get_gtk_property
    const linspace(x,y,z) = range(x,stop=y,length=z)
    const indmin = argmin
    const find = findall
    const indmax = argmax
    Base.round(x::Number, digits) = round(x; digits=digits)
end

export makeRHD, RHD2164, RHD2132,  makegui, Debug, Intan_GUI

const MyFilter = DSP.Filters.DF2TFilter{DSP.Filters.SecondOrderSections{Float64,Float64},Array{Float64,2}}

include("types.jl")
include("constants.jl")
include("gtk_helpers.jl")
include("gui/single_channel_canvas.jl")
include("gui/cluster_treeview.jl")
include("gui/multi_canvas_selection.jl")
include("gui/soft_scope.jl")
include("gui/event_display.jl")
include("gui/spectrogram.jl")
include("gui/multi_channel_display.jl")
include("gui/reference_channel.jl")
include("gui/parameter_table.jl")
include("gui/filters.jl")
include("gui/thresholds.jl")

#functions needed for evaluation board from Intan
include("ICs/Opal_Kelly_FPGA/opalkelly_gui.jl")

include("rhd2000evalboard.jl")
include("rhd2000registers.jl")
include("gui.jl")
include("plotting.jl")
include("offline.jl")
include("task_list.jl")
include("save_load.jl")
include("benchmark.jl")

#Spike Sorting
include("sorting/windows.jl")
include("sorting/templates.jl")

#Graphics
include("graphics_help/cairo.jl")

end
