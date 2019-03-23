module Gui_Test

using Intan, SpikeSorting, Gtk.ShortNames, MAT, JLD

if VERSION > v"0.7-"
    using Test
else
    using Base.Test
end

myamp=RHD2164("PortA1")
d=Debug(string(dirname(Base.source_path()),"/data/qq.mat"),"qq")
myt=Task_NoTask()
myfpga=FPGA(1,myamp)
(myrhd,ss,myfpgas)=makeRHD([myfpga],debug=d)

handles = makegui(myrhd,ss,myt,myfpgas)

sleep(1.0)



    @test handles.sc.mi == (0.0,0.0)



#=
Callback Testing
=#

#Initialization
Intan.init_cb(handles.init.handle,(handles,myrhd,myt,myfpgas))


    @test myfpgas[1].numDataStreams == 2
    @test myfpgas[1].dataStreamEnabled == [1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0]



#Run
setproperty!(handles.run,:active,true)
sleep(1.0)
Intan.run_cb(handles.run.handle,(handles,myrhd,ss,myt,myfpgas))


    myreads=myrhd.reads
    for i=1:5
        sleep(0.5)
        @test myrhd.reads > myreads
        myreads=myrhd.reads
    end


#Calibration
sleep(1.0)


    @test myrhd.cal == 3


#Slider 1
sleep(1.0)

    for i=1:4
        setproperty!(handles.adj,:value,i)
        Intan.update_c1(handles.adj.handle,(handles,))
        sleep(1.0)
        @test handles.num16 == i
        @test handles.sc.spike == 16*i-16+handles.num
    end


#Slider 2
sleep(1.0)

    for i=1:4
        setproperty!(handles.adj2,:value,i)
        Intan.update_c2(handles)
        sleep(1.0)
        @test handles.num == i
        @test handles.sc.spike == 16*handles.num16-16+i
    end


#=
Threshold Test
=#

press=Gtk.GdkEventButton(Gtk.GdkEventType.BUTTON_PRESS, Gtk.gdk_window(handles.sc.thres_widgets.show),Int8(0),UInt32(0),0.0,0.0,convert(Ptr{Float64},C_NULL),UInt32(0),UInt32(1),C_NULL,0.0,0.0)
signal_emit(handles.sc.thres_widgets.show,"clicked",Bool,press)

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

#16 Channel Select

press=Gtk.GdkEventButton(Gtk.GdkEventType.BUTTON_PRESS, Gtk.gdk_window(handles.c),Int8(0),UInt32(0),1.0,1.0,convert(Ptr{Float64},C_NULL),UInt32(0),UInt32(1),C_NULL,0.0,0.0)
signal_emit(handles.c,"button-press-event",Bool,press)
sleep(1.0)


    @test handles.sc.spike == 49


press=Gtk.GdkEventButton(Gtk.GdkEventType.BUTTON_PRESS, Gtk.gdk_window(handles.c),Int8(0),UInt32(0),200.0,1.0,convert(Ptr{Float64},C_NULL),UInt32(0),UInt32(1),C_NULL,0.0,0.0)
signal_emit(handles.c,"button-press-event",Bool,press)
sleep(1.0)


    @test handles.sc.spike == 53


#32 Channel Select

#Change to 32 channel
press=Gtk.GdkEventButton(Gtk.GdkEventType.BUTTON_PRESS, Gtk.gdk_window(handles.rb1[2]),Int8(0),UInt32(0),0.0,0.0,convert(Ptr{Float64},C_NULL),UInt32(0),UInt32(1),C_NULL,0.0,0.0)
signal_emit(handles.rb1[2],"clicked",Bool,press)
sleep(1.0)

press=Gtk.GdkEventButton(Gtk.GdkEventType.BUTTON_PRESS, Gtk.gdk_window(handles.c),Int8(0),UInt32(0),1.0,1.0,convert(Ptr{Float64},C_NULL),UInt32(0),UInt32(1),C_NULL,0.0,0.0)
signal_emit(handles.c,"button-press-event",Bool,press)
sleep(1.0)


    @test handles.sc.spike == 33


press=Gtk.GdkEventButton(Gtk.GdkEventType.BUTTON_PRESS, Gtk.gdk_window(handles.c),Int8(0),UInt32(0),150.0,1.0,convert(Ptr{Float64},C_NULL),UInt32(0),UInt32(1),C_NULL,0.0,0.0)
signal_emit(handles.c,"button-press-event",Bool,press)
sleep(1.0)


    @test handles.sc.spike == 39



#=
RadioButtons
=#
for i=2:5
    press=Gtk.GdkEventButton(Gtk.GdkEventType.BUTTON_PRESS, Gtk.gdk_window(handles.rb1[i]),Int8(0),UInt32(0),0.0,0.0,convert(Ptr{Float64},C_NULL),UInt32(0),UInt32(1),C_NULL,0.0,0.0)
    signal_emit(handles.rb1[i],"clicked",Bool,press)
    sleep(1.0)
    facts() do
	@test handles.c_right_top == i
    end
end

for i=1:6
    press=Gtk.GdkEventButton(Gtk.GdkEventType.BUTTON_PRESS, Gtk.gdk_window(handles.rb2[i]),Int8(0),UInt32(0),0.0,0.0,convert(Ptr{Float64},C_NULL),UInt32(0),UInt32(1),C_NULL,0.0,0.0)
    signal_emit(handles.rb2[i],"clicked",Bool,press)
    sleep(1.0)
    facts() do
	@test handles.c_right_bottom == i
    end
end

#=
Soft Scope
=#

press=Gtk.GdkEventButton(Gtk.GdkEventType.BUTTON_PRESS, Gtk.gdk_window(handles.rb2[4]),Int8(0),UInt32(0),0.0,0.0,convert(Ptr{Float64},C_NULL),UInt32(0),UInt32(1),C_NULL,0.0,0.0)
signal_emit(handles.rb2[4],"clicked",Bool,press)

sleep(1.0)

for i=0:4
    Intan.scope_popup_v_cb(handles.run.handle,(handles,i))
    sleep(1.0)
end

Intan.scope_popup_v_cb(handles.run.handle,(handles,2))
sleep(1.0)

for i=0:4
    Intan.scope_popup_t_cb(handles.run.handle,(handles,i))
    sleep(1.0)
end

Intan.scope_popup_t_cb(handles.run.handle,(handles,2))
sleep(1.0)

for i=0:1
    Intan.scope_popup_thres_cb(handles.run.handle,(handles,i))
    sleep(1.0)
end

#=
Popup Tests
=#

press=Gtk.GdkEventButton(Gtk.GdkEventType.BUTTON_PRESS, Gtk.gdk_window(handles.rb1[1]),Int8(0),UInt32(0),0.0,0.0,convert(Ptr{Float64},C_NULL),UInt32(0),UInt32(1),C_NULL,0.0,0.0)
signal_emit(handles.rb1[1],"clicked",Bool,press)
sleep(1.0)

press=Gtk.GdkEventButton(Gtk.GdkEventType.BUTTON_PRESS, Gtk.gdk_window(handles.c),Int8(0),UInt32(0),1.0,1.0,convert(Ptr{Float64},C_NULL),UInt32(0),UInt32(1),C_NULL,0.0,0.0)
signal_emit(handles.c,"button-press-event",Bool,press)
sleep(1.0)

Intan.popup_enable_cb(handles.run.handle,(handles,myrhd))


    @test handles.enabled[handles.sc.spike] == true


Intan.popup_disable_cb(handles.run.handle,(handles,myrhd))


    @test handles.enabled[handles.sc.spike] == false


press=Gtk.GdkEventButton(Gtk.GdkEventType.BUTTON_PRESS, Gtk.gdk_window(handles.rb1[2]),Int8(0),UInt32(0),0.0,0.0,convert(Ptr{Float64},C_NULL),UInt32(0),UInt32(1),C_NULL,0.0,0.0)
signal_emit(handles.rb1[2],"clicked",Bool,press)
sleep(1.0)

press=Gtk.GdkEventButton(Gtk.GdkEventType.BUTTON_PRESS, Gtk.gdk_window(handles.c),Int8(0),UInt32(0),1.0,1.0,convert(Ptr{Float64},C_NULL),UInt32(0),UInt32(1),C_NULL,0.0,0.0)
signal_emit(handles.c,"button-press-event",Bool,press)
sleep(1.0)

Intan.popup_enable_cb(handles.run.handle,(handles,myrhd))


    @test handles.enabled[handles.sc.spike] == true


Intan.popup_disable_cb(handles.run.handle,(handles,myrhd))


    @test handles.enabled[handles.sc.spike] == false




#=
SAVE LOAD Test
=#

sleep(1.0);

setproperty!(handles.run,:active,false)
sleep(1.0);
#=
Intan.run_cb(handles.run.handle,(handles,myrhd,ss,myt,myfpgas))

sleep(1.0);

myv=parse_v(myrhd.save.v)

facts() do
    @test size(myv,2) == 64
end

mys_m=save_ts_mat(myrhd.save.ts)
mys_j=save_ts_jld(myrhd.save.ts)

facts() do
    @test length(mys_m) == length(mys_j)
end

=#
#=
Close
=#

destroy(handles.win)

end
