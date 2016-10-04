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

myamp=RHD2164("PortA1")
myfpga=FPGA(1,myamp)

facts() do
    @fact myfpga.numDataStreams --> 0
    @fact myfpga.dataStreamEnabled --> zeros(Int64,1,Intan.MAX_NUM_DATA_STREAMS)
    @fact myfpga.amps --> [0,8]
end

#=
Single Core Data Structure
=#
myamp=RHD2164("PortA1")
myt=Task_NoTask()
mys=SaveNone()
d=Debug(string(dirname(Base.source_path()),"/data/qq.mat"),"qq")

myfpga=FPGA(1,myamp)

myrhd=makeRHD([myfpga],myt,debug=d,sav=mys);

facts() do
    @fact myrhd.v --> zeros(Int16, Intan.SAMPLES_PER_DATA_BLOCK,64)
    @fact length(myrhd.s) --> 64
    @fact typeof(myrhd.s) --> Array{SpikeSorting.Sorting_1,1}
    @fact typeof(myrhd.buf) --> Array{SpikeSorting.Spike,2}
    @fact size(myrhd.buf,2) --> 64
    @fact myrhd.nums --> zeros(Int64,64)
    @fact myrhd.time --> zeros(UInt32,Intan.SAMPLES_PER_DATA_BLOCK,1)
end

Intan.init_board!(myrhd)

facts() do
    @fact myrhd.fpga[1].numDataStreams --> 2
    @fact myrhd.fpga[1].dataStreamEnabled --> [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
    @fact myrhd.fpga[1].sampleRate --> 30000
    @fact myrhd.fpga[1].numWords --> 52800
    @fact myrhd.fpga[1].numBytesPerBlock --> 105600
end

#=
Multi Core Data Structure
=#
myamp=RHD2132("PortA1")
d=Debug(string(dirname(Base.source_path()),"/data/qq.mat"),"qq")
myt=Task_NoTask()
myfpga1=FPGA(1,myamp)
myfpga2=FPGA(2,myamp)
myrhd2=makeRHD([myfpga1,myfpga2],myt,debug=d,sav=mys,parallel=true);

facts() do
    @fact myrhd2.v --> zeros(Int64, Intan.SAMPLES_PER_DATA_BLOCK,64)
    @fact length(myrhd2.s) --> 64
    @fact typeof(myrhd2.s) --> DistributedArrays.DArray{SpikeSorting.Sorting_1,1,Array{SpikeSorting.Sorting_1,1}}
    @fact typeof(myrhd2.buf) --> SharedArray{SpikeSorting.Spike,2}
    @fact size(myrhd2.buf,2) --> 64
    @fact myrhd2.nums --> zeros(Int64,64)
end

#Intan.init_board!(myrhd2)

#=
facts() do
    @fact myrhd.fpga[1].numDataStreams --> 1
    @fact myrhd.fpga[1].dataStreamEnabled --> [1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
    @fact myrhd.fpga[1].sampleRate --> 30000
    @fact myrhd.fpga[1].numWords --> 31200
    @fact myrhd.fpga[1].numBytesPerBlock --> 62400
end
=#
#=
Sample Rate Testing
=#


myamp=RHD2164("PortA1")
myt=Task_NoTask()
mys=SaveNone()
d=Debug(string(dirname(Base.source_path()),"/data/qq.mat"),"qq")

myfpga=FPGA(1,myamp)

myrhd=makeRHD([myfpga],myt,debug=d,sav=mys);

Intan.init_board!(myrhd)


facts() do

    for i in [1000,1250,1500,2000,2500,3000,3333,4000,5000,6250,8000,10000,12500,15000,20000,25000,30000]
        Intan.setSampleRate(myrhd.fpga[1],i,myrhd.debug.state)
        @fact myrhd.fpga[1].sampleRate --> i
    end
end
end
