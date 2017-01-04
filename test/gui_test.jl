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
Threshold Test
=#

press=Gtk.GdkEventButton(Gtk.GdkEventType.BUTTON_PRESS, Gtk.gdk_window(handles.thres_widgets.show),Int8(0),UInt32(0),0.0,0.0,convert(Ptr{Float64},C_NULL),UInt32(0),UInt32(1),C_NULL,0.0,0.0)
signal_emit(handles.thres_widgets.show,"clicked",Bool,press)

sleep(5.0)

#=
Spike Button Tests
=#

press=Gtk.GdkEventButton(Gtk.GdkEventType.BUTTON_PRESS, Gtk.gdk_window(handles.spike_widgets.refresh),Int8(0),UInt32(0),0.0,0.0,convert(Ptr{Float64},C_NULL),UInt32(0),UInt32(1),C_NULL,0.0,0.0)
signal_emit(handles.spike_widgets.refresh,"clicked",Bool,press)

sleep(1.0)

#=
Gain Button Tests
=#



#=
Right canvas callbacks
=#

press=Gtk.GdkEventButton(Gtk.GdkEventType.BUTTON_PRESS, Gtk.gdk_window(handles.c),Int8(0),UInt32(0),1.0,1.0,convert(Ptr{Float64},C_NULL),UInt32(0),UInt32(1),C_NULL,0.0,0.0)
signal_emit(handles.c,"button-press-event",Bool,press)

sleep(1.0)

facts() do

	@fact handles.spike --> 49

end

press=Gtk.GdkEventButton(Gtk.GdkEventType.BUTTON_PRESS, Gtk.gdk_window(handles.c),Int8(0),UInt32(0),200.0,1.0,convert(Ptr{Float64},C_NULL),UInt32(0),UInt32(1),C_NULL,0.0,0.0)
signal_emit(handles.c,"button-press-event",Bool,press)

sleep(1.0)

facts() do

	@fact handles.spike --> 53

end

#=
RadioButtons
=#

press=Gtk.GdkEventButton(Gtk.GdkEventType.BUTTON_PRESS, Gtk.gdk_window(handles.rb1[2]),Int8(0),UInt32(0),0.0,0.0,convert(Ptr{Float64},C_NULL),UInt32(0),UInt32(1),C_NULL,0.0,0.0)
signal_emit(handles.rb1[2],"clicked",Bool,press)

sleep(1.0)

press=Gtk.GdkEventButton(Gtk.GdkEventType.BUTTON_PRESS, Gtk.gdk_window(handles.rb1[3]),Int8(0),UInt32(0),0.0,0.0,convert(Ptr{Float64},C_NULL),UInt32(0),UInt32(1),C_NULL,0.0,0.0)
signal_emit(handles.rb1[3],"clicked",Bool,press)

sleep(1.0)

press=Gtk.GdkEventButton(Gtk.GdkEventType.BUTTON_PRESS, Gtk.gdk_window(handles.rb1[4]),Int8(0),UInt32(0),0.0,0.0,convert(Ptr{Float64},C_NULL),UInt32(0),UInt32(1),C_NULL,0.0,0.0)
signal_emit(handles.rb1[4],"clicked",Bool,press)

sleep(1.0)

press=Gtk.GdkEventButton(Gtk.GdkEventType.BUTTON_PRESS, Gtk.gdk_window(handles.rb1[5]),Int8(0),UInt32(0),0.0,0.0,convert(Ptr{Float64},C_NULL),UInt32(0),UInt32(1),C_NULL,0.0,0.0)
signal_emit(handles.rb1[5],"clicked",Bool,press)

sleep(1.0)

press=Gtk.GdkEventButton(Gtk.GdkEventType.BUTTON_PRESS, Gtk.gdk_window(handles.rb1[1]),Int8(0),UInt32(0),0.0,0.0,convert(Ptr{Float64},C_NULL),UInt32(0),UInt32(1),C_NULL,0.0,0.0)
signal_emit(handles.rb1[1],"clicked",Bool,press)

sleep(1.0)

press=Gtk.GdkEventButton(Gtk.GdkEventType.BUTTON_PRESS, Gtk.gdk_window(handles.rb2[2]),Int8(0),UInt32(0),0.0,0.0,convert(Ptr{Float64},C_NULL),UInt32(0),UInt32(1),C_NULL,0.0,0.0)
signal_emit(handles.rb2[2],"clicked",Bool,press)

sleep(1.0)

press=Gtk.GdkEventButton(Gtk.GdkEventType.BUTTON_PRESS, Gtk.gdk_window(handles.rb2[3]),Int8(0),UInt32(0),0.0,0.0,convert(Ptr{Float64},C_NULL),UInt32(0),UInt32(1),C_NULL,0.0,0.0)
signal_emit(handles.rb2[3],"clicked",Bool,press)

sleep(1.0)

press=Gtk.GdkEventButton(Gtk.GdkEventType.BUTTON_PRESS, Gtk.gdk_window(handles.rb2[4]),Int8(0),UInt32(0),0.0,0.0,convert(Ptr{Float64},C_NULL),UInt32(0),UInt32(1),C_NULL,0.0,0.0)
signal_emit(handles.rb2[4],"clicked",Bool,press)

sleep(1.0)

press=Gtk.GdkEventButton(Gtk.GdkEventType.BUTTON_PRESS, Gtk.gdk_window(handles.rb2[5]),Int8(0),UInt32(0),0.0,0.0,convert(Ptr{Float64},C_NULL),UInt32(0),UInt32(1),C_NULL,0.0,0.0)
signal_emit(handles.rb2[5],"clicked",Bool,press)

sleep(1.0)

press=Gtk.GdkEventButton(Gtk.GdkEventType.BUTTON_PRESS, Gtk.gdk_window(handles.rb2[6]),Int8(0),UInt32(0),0.0,0.0,convert(Ptr{Float64},C_NULL),UInt32(0),UInt32(1),C_NULL,0.0,0.0)
signal_emit(handles.rb2[6],"clicked",Bool,press)

sleep(1.0)

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

#destroy(handles.win)

end
