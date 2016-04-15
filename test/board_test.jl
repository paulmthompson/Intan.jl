module Board_Test

using Intan, FactCheck, SpikeSorting, DistributedArrays

#64 channel amp check
facts() do
    myamp=RHD2164("PortA1")
    @fact myamp --> [0,8]
    myamp=RHD2164("PortA2")
    @fact myamp --> [1,9]
    myamp=RHD2164("PortB1")
    @fact myamp --> [2,10]
    myamp=RHD2164("PortB2")
    @fact myamp --> [3,11]
    myamp=RHD2164("PortC1")
    @fact myamp --> [4,12]
    myamp=RHD2164("PortC2")
    @fact myamp --> [5,13]
    myamp=RHD2164("PortD1")
    @fact myamp --> [6,14]
    myamp=RHD2164("PortD2")
    @fact myamp --> [7,15]
end

#32 channel amp check
facts() do
    myamp=RHD2132("PortA1")
    @fact myamp --> [0]
    myamp=RHD2132("PortA2")
    @fact myamp --> [1]
    myamp=RHD2132("PortB1")
    @fact myamp --> [2]
    myamp=RHD2132("PortB2")
    @fact myamp --> [3]
    myamp=RHD2132("PortC1")
    @fact myamp --> [4]
    myamp=RHD2132("PortC2")
    @fact myamp --> [5]
    myamp=RHD2132("PortD1")
    @fact myamp --> [6]
    myamp=RHD2132("PortD2")
    @fact myamp --> [7]
end

#=
Single Core Data Structure
=#
myamp=RHD2164("PortA1")
myt=Task_NoTask()
d=Debug(string(dirname(Base.source_path()),"/data/qq.mat"),"qq")
myrhd=makeRHD(myamp,"single",myt,debug=d);

facts() do
    @fact myrhd.numDataStreams --> 2
    @fact myrhd.dataStreamEnabled --> zeros(Int64,1,Intan.MAX_NUM_DATA_STREAMS)
    @fact myrhd.amps --> [0,8]
    @fact myrhd.v --> zeros(Int64, Intan.SAMPLES_PER_DATA_BLOCK,64)
    @fact length(myrhd.s) --> 64
    @fact typeof(myrhd.s) --> Array{SpikeSorting.Sorting_1,1}
    @fact myrhd.time --> zeros(Int32,Intan.SAMPLES_PER_DATA_BLOCK)
    @fact typeof(myrhd.buf) --> Array{SpikeSorting.Spike,2}
    @fact size(myrhd.buf,2) --> 64
    @fact myrhd.nums --> zeros(Int64,64)
    @fact myrhd.kins --> zeros(Float64,Intan.SAMPLES_PER_DATA_BLOCK, 8)
end

#=
Multi Core Data Structure
=#
myamp=RHD2132("PortA1")
d=Debug(string(dirname(Base.source_path()),"/data/qq.mat"),"qq")
myt=Task_NoTask()
myrhd=makeRHD(myamp,"parallel",myt,debug=d);

facts() do
    @fact myrhd.numDataStreams --> 1
    @fact myrhd.dataStreamEnabled --> zeros(Int64,1,Intan.MAX_NUM_DATA_STREAMS)
    @fact myrhd.amps --> [0]
    @fact myrhd.v --> zeros(Int64, Intan.SAMPLES_PER_DATA_BLOCK,32)
    @fact length(myrhd.s) --> 32
    @fact typeof(myrhd.s) --> DistributedArrays.DArray{SpikeSorting.Sorting_1,1,Array{SpikeSorting.Sorting_1,1}}
    @fact myrhd.time --> zeros(Int32,Intan.SAMPLES_PER_DATA_BLOCK)
    @fact typeof(myrhd.buf) --> SharedArray{SpikeSorting.Spike,2}
    @fact size(myrhd.buf,2) --> 32
    @fact myrhd.nums --> zeros(Int64,32)
    @fact myrhd.kins --> zeros(Float64,Intan.SAMPLES_PER_DATA_BLOCK, 8)
end
end
