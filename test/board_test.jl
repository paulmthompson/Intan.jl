module Board_Test

using Intan, SpikeSorting, DistributedArrays

if VERSION > v"0.7-"
    using Test
else
    using Base.Test
end

#64 channel amp check

    myamp=RHD2164("PortA1")
    @test myamp == [0,8]
    myamp=RHD2164("PortA2")
    @test myamp == [1,9]
    myamp=RHD2164("PortB1")
    @test myamp == [2,10]
    myamp=RHD2164("PortB2")
    @test myamp == [3,11]
    myamp=RHD2164("PortC1")
    @test myamp == [4,12]
    myamp=RHD2164("PortC2")
    @test myamp == [5,13]
    myamp=RHD2164("PortD1")
    @test myamp == [6,14]
    myamp=RHD2164("PortD2")
    @test myamp == [7,15]


#32 channel amp check

    myamp=RHD2132("PortA1")
    @test myamp == [0]
    myamp=RHD2132("PortA2")
    @test myamp == [1]
    myamp=RHD2132("PortB1")
    @test myamp == [2]
    myamp=RHD2132("PortB2")
    @test myamp == [3]
    myamp=RHD2132("PortC1")
    @test myamp == [4]
    myamp=RHD2132("PortC2")
    @test myamp == [5]
    myamp=RHD2132("PortD1")
    @test myamp == [6]
    myamp=RHD2132("PortD2")
    @test myamp == [7]


myamp=RHD2164("PortA1")
myfpga=FPGA(1,myamp)


    @test myfpga.numDataStreams == 0
    @test myfpga.dataStreamEnabled == zeros(Int64,1,Intan.MAX_NUM_DATA_STREAMS)
    @test myfpga.amps == [0,8]


#=
Single Core Data Structure
=#
myamp=RHD2164("PortA1")
myt=Task_NoTask()
d=Debug(string(dirname(Base.source_path()),"/data/qq.mat"),"qq")

myfpga=FPGA(1,myamp)

(myrhd,ss,myfpgas)=makeRHD([myfpga],debug=d);


    @test myrhd.v == zeros(Int16, Intan.SAMPLES_PER_DATA_BLOCK,64)
    @test length(ss) == 64
    @test typeof(ss) == Array{SpikeSorting.Sorting_1,1}
    @test typeof(myrhd.buf) == Array{SpikeSorting.Spike,2}
    @test size(myrhd.buf,2) == 64
    @test myrhd.nums == zeros(Int64,64)
    @test myrhd.time == zeros(UInt32,Intan.SAMPLES_PER_DATA_BLOCK,1)


Intan.init_board!(myrhd,myfpgas)


    @test myfpgas[1].numDataStreams == 2
    @test myfpgas[1].dataStreamEnabled == [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
    @test myfpgas[1].sampleRate == 30000
    @test myfpgas[1].numWords == Intan.SAMPLES_PER_DATA_BLOCK * (4+2+(2*36) +8+2)
    @test myfpgas[1].numBytesPerBlock == Intan.SAMPLES_PER_DATA_BLOCK * (4+2+(2*36) +8+2) * 2

#Intan.init_board!(myrhd2)

#=

    @test myrhd.fpga[1].numDataStreams --> 1
    @test myrhd.fpga[1].dataStreamEnabled --> [1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
    @test myrhd.fpga[1].sampleRate --> 30000
    @test myrhd.fpga[1].numWords --> 31200
    @test myrhd.fpga[1].numBytesPerBlock --> 62400

=#
#=
Sample Rate Testing
=#


myamp=RHD2164("PortA1")
myt=Task_NoTask()
d=Debug(string(dirname(Base.source_path()),"/data/qq.mat"),"qq")

myfpga=FPGA(1,myamp)

(myrhd,ss,myfpgas)=makeRHD([myfpga],debug=d);

Intan.init_board!(myrhd,myfpgas)




    for i in [1000,1250,1500,2000,2500,3000,3333,4000,5000,6250,8000,10000,12500,15000,20000,25000,30000]
        Intan.setSampleRate(myfpgas[1],i,myrhd.debug.state)
        @test myfpgas[1].sampleRate == i
    end

end
