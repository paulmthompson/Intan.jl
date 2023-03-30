#=
Functions for the time counter in the GUI
Reads time from the FPGA and displays it in real time in seconds
=#
function _make_clock()

    s_label=Label("0")
    m_label=Label("0")
    h_label=Label("0")
    sm_label=Label(":")
    mh_label=Label(":")

    frame_time=Frame("Time Elapsed")
    hbox_time=ButtonBox(:h)
    push!(frame_time,hbox_time)

    push!(hbox_time,h_label)
    push!(hbox_time,mh_label)
    push!(hbox_time,m_label)
    push!(hbox_time,sm_label)
    push!(hbox_time,s_label)

    mytime_widgets=mytime(0,h_label,0,m_label,0,s_label)

    (mytime_widgets,frame_time)
end

function update_time(rhd::RHD2000,han::Gui_Handles)

    total_seconds=convert(Int64,div(rhd.time[1,1],rhd.sr))

    this_h=div(total_seconds,3600)

    total_seconds=total_seconds - this_h*3600

    this_m=div(total_seconds,60)

    this_s=total_seconds - this_m*60

    if this_s != han.time.s
        set_gtk_property!(han.time.s_l,:label,string(this_s))
        han.time.s=this_s
    end
    if this_m != han.time.m
        set_gtk_property!(han.time.m_l,:label,string(this_m))
        han.time.m=this_m
    end
    if this_h != han.time.h
        set_gtk_property!(han.time.h_l,:label,string(this_h))
        han.time.h=this_h
    end

    nothing
end
