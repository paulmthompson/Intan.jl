module Gui_Test

using FactCheck, Intan, SpikeSorting, Gtk.ShortNames, MAT, JLD

myamp=RHD2164("PortA1")
d=Debug(string(dirname(Base.source_path()),"/data/qq.mat"),"qq")
myt=Task_NoTask()
mys=SaveAll()
myfpga=FPGA(1,myamp)
myrhd=makeRHD([myfpga],myt,debug=d,sav=mys)

handles = makegui(myrhd)

sleep(1.0)

facts() do

    @fact handles.mi --> (0.0,0.0)
    
end

#=
Callback Testing
=#

#Initialization
Intan.init_cb(handles.init.handle,(handles,myrhd))

facts() do
    @fact myrhd.fpga[1].numDataStreams --> 2
    @fact myrhd.fpga[1].dataStreamEnabled --> [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
end


#Run
setproperty!(handles.run,:active,true)
sleep(1.0)
Intan.run_cb(handles.run.handle,(handles,myrhd))

facts() do
    myreads=myrhd.reads
    for i=1:5
        sleep(0.5)
        @fact myrhd.reads --> greater_than(myreads)
        myreads=myrhd.reads
    end
end

#Calibration
sleep(1.0)
setproperty!(handles.cal,:active,false)
Intan.cal_cb(handles.cal.handle,(handles,myrhd))
sleep(1.0)

facts() do
    @fact myrhd.cal --> 3
end

#Slider 1
sleep(1.0)
facts() do
    for i=1:4
        setproperty!(handles.adj,:value,i)
        Intan.update_c1(handles.adj.handle,(handles,myrhd))
        sleep(1.0)
        @fact handles.num16 --> i
        @fact handles.spike --> 16*i-16+handles.num
    end
end

#Slider 2
sleep(1.0)
facts() do
    for i=1:4
        setproperty!(handles.adj2,:value,i)
        Intan.update_c2(handles,myrhd)
        sleep(1.0)
        @fact handles.num --> i
        @fact handles.spike --> 16*handles.num16-16+i
    end
end

#=
SAVE LOAD Test
=#

myv=parse_v(myrhd.save.v)

facts() do

    @fact size(myv,2) --> 64
end

mys_m=save_ts_mat(myrhd.save.ts)
mys_j=save_ts_jld(myrhd.save.ts)

facts() do
    @fact length(mys_m) --> length(mys_j)
end

end
