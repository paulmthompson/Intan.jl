module Sorting_Test

using FactCheck, Intan, SpikeSorting, Gtk.ShortNames, Cairo, MAT, JLD

myamp=RHD2164("PortA1")
d=Debug(string(dirname(Base.source_path()),"/data/qq.mat"),"qq")
myt=Task_NoTask()
myfpga=FPGA(1,myamp)
(myrhd,ss,myfpgas)=makeRHD([myfpga],debug=d)

handles = makegui(myrhd,ss,myt,myfpgas)

sleep(1.0)

#Initialization
Intan.init_cb(handles.init.handle,(handles,myrhd,myt,myfpgas))

#Run
setproperty!(handles.run,:active,true)
sleep(1.0)
Intan.run_cb(handles.run.handle,(handles,myrhd,ss,myt,myfpgas))

#Calibration
sleep(1.0)
setproperty!(handles.cal,:active,false)
Intan.cal_cb(handles.cal.handle,(handles,myrhd))
sleep(1.0)

myctx2=Gtk.getgc(handles.sc.c2)

sleep(1.0)

#Add Unit
Intan.b2_cb_template(handles.run.handle,(handles,))

press=Gtk.GdkEventButton(Gtk.GdkEventType.BUTTON_PRESS, Gtk.gdk_window(handles.sc.c2),Int8(0),UInt32(0),142.0,252.0,convert(Ptr{Float64},C_NULL),UInt32(0),UInt32(1),C_NULL,0.0,0.0)
signal_emit(handles.sc.c2,"button-press-event",Bool,press)

press=Gtk.GdkEventButton(Gtk.GdkEventType.BUTTON_PRESS, Gtk.gdk_window(handles.sc.c2),Int8(0),UInt32(0),110.0,253.0,convert(Ptr{Float64},C_NULL),UInt32(0),UInt32(1),C_NULL,0.0,0.0)
signal_emit(handles.sc.c2,"button-release-event",Bool,press)

sleep(1.0)

facts() do

    @fact handles.total_clus[1] --> 1
    @fact handles.total_clus[2] --> 0
end

#Delete Unit
Intan.b1_cb_template(handles.run.handle,(handles,))

facts() do

    @fact handles.total_clus[1] --> 0
    @fact handles.total_clus[2] --> 0
end

sleep(1.0)

#Add Unit
Intan.b2_cb_template(handles.run.handle,(handles,))

press=Gtk.GdkEventButton(Gtk.GdkEventType.BUTTON_PRESS, Gtk.gdk_window(handles.sc.c2),Int8(0),UInt32(0),142.0,252.0,convert(Ptr{Float64},C_NULL),UInt32(0),UInt32(1),C_NULL,0.0,0.0)
signal_emit(handles.sc.c2,"button-press-event",Bool,press)

press=Gtk.GdkEventButton(Gtk.GdkEventType.BUTTON_PRESS, Gtk.gdk_window(handles.sc.c2),Int8(0),UInt32(0),110.0,253.0,convert(Ptr{Float64},C_NULL),UInt32(0),UInt32(1),C_NULL,0.0,0.0)
signal_emit(handles.sc.c2,"button-release-event",Bool,press)

sleep(1.0)

#Add Second Unit
Intan.b2_cb_template(handles.run.handle,(handles,))

press=Gtk.GdkEventButton(Gtk.GdkEventType.BUTTON_PRESS, Gtk.gdk_window(handles.sc.c2),Int8(0),UInt32(0),186.0,287.0,convert(Ptr{Float64},C_NULL),UInt32(0),UInt32(1),C_NULL,0.0,0.0)
signal_emit(handles.sc.c2,"button-press-event",Bool,press)

press=Gtk.GdkEventButton(Gtk.GdkEventType.BUTTON_PRESS, Gtk.gdk_window(handles.sc.c2),Int8(0),UInt32(0),156.0,293.0,convert(Ptr{Float64},C_NULL),UInt32(0),UInt32(1),C_NULL,0.0,0.0)
signal_emit(handles.sc.c2,"button-release-event",Bool,press)

sleep(1.0)

facts() do

    @fact handles.total_clus[1] --> 2
    @fact handles.total_clus[2] --> 0
end

#Change second unit

press=Gtk.GdkEventButton(Gtk.GdkEventType.BUTTON_PRESS, Gtk.gdk_window(handles.sc.c2),Int8(0),UInt32(0),186.0,287.0,convert(Ptr{Float64},C_NULL),UInt32(0),UInt32(1),C_NULL,0.0,0.0)
signal_emit(handles.sc.c2,"button-press-event",Bool,press)

press=Gtk.GdkEventButton(Gtk.GdkEventType.BUTTON_PRESS, Gtk.gdk_window(handles.sc.c2),Int8(0),UInt32(0),156.0,293.0,convert(Ptr{Float64},C_NULL),UInt32(0),UInt32(1),C_NULL,0.0,0.0)
signal_emit(handles.sc.c2,"button-release-event",Bool,press)

sleep(1.0)

facts() do

    @fact handles.total_clus[1] --> 2
    @fact handles.total_clus[2] --> 0
end

#Show Templates
Intan.b4_cb_template(handles.run.handle,(handles,))

sleep(1.0)

#Set draw template checkbox
setproperty!(handles.sort_widgets.check,:active,true)

sleep(1.0)

#Collect Templates
press=Gtk.GdkEventButton(Gtk.GdkEventType.BUTTON_PRESS, Gtk.gdk_window(handles.sort_widgets.b3),Int8(0),UInt32(0),0.0,0.0,convert(Ptr{Float64},C_NULL),UInt32(0),UInt32(1),C_NULL,0.0,0.0)
signal_emit(handles.sort_widgets.b3,"clicked",Bool,press)

sleep(1.0)

press=Gtk.GdkEventButton(Gtk.GdkEventType.BUTTON_PRESS, Gtk.gdk_window(handles.sort_widgets.b3),Int8(0),UInt32(0),0.0,0.0,convert(Ptr{Float64},C_NULL),UInt32(0),UInt32(1),C_NULL,0.0,0.0)
signal_emit(handles.sort_widgets.b3,"clicked",Bool,press)

sleep(1.0)

press=Gtk.GdkEventButton(Gtk.GdkEventType.BUTTON_PRESS, Gtk.gdk_window(handles.sc.c2),Int8(0),UInt32(0),156.0,293.0,convert(Ptr{Float64},C_NULL),UInt32(0),UInt32(1),C_NULL,0.0,0.0)
signal_emit(handles.sc.c2,"button-release-event",Bool,press)

sleep(1.0)

press=Gtk.GdkEventButton(Gtk.GdkEventType.BUTTON_PRESS, Gtk.gdk_window(handles.sc.pause_button),Int8(0),UInt32(0),0.0,0.0,convert(Ptr{Float64},C_NULL),UInt32(0),UInt32(1),C_NULL,0.0,0.0)
signal_emit(handles.sc.pause_button,"clicked",Bool,press)

sleep(1.0)

facts() do

    @fact handles.total_clus[1] --> 2
    @fact handles.total_clus[2] --> 0
end

end
