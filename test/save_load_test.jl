
module Save_Load_Test

using Intan, FactCheck, MAT, JLD

myv=parse_v(64)

facts() do

    @fact size(myv,2) --> 64
end

mys_m=save_mat(64)
mys_j=save_jld(64)

facts() do
    @fact length(mys_m) --> length(mys_j)
end

end
