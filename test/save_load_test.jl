
module Save_Load_Test

using Intan, FactCheck, MAT, JLD

myv=parse_v()

facts() do

    @fact size(myv,2) --> 64
end

mys_m=save_ts_mat()
mys_j=save_ts_jld()

facts() do
    @fact length(mys_m) --> length(mys_j)
end

end
