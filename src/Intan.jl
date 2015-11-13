
module Intan

using HDF5, DistributedArrays, SortSpikes

export RHD2000, init_board

include("rhd2000evalboard.jl")
include("rhd2000registers.jl")

end
