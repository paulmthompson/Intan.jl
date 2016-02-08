module TestSetup

Pkg.clone("https://github.com/paulmthompson/SpikeSorting.jl")

using Intan

include("board_test.jl")

end
