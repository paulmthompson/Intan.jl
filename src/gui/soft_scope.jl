
function _make_scope_gui()

    popupmenu_scope = Menu()
    popupmenu_voltage=MenuItem("Voltage Gain")
    popupmenu_time=MenuItem("ms/div")
    popupmenu_thres=MenuItem("Threshold")
    popupmenu_signal=MenuItem("Signal")
    push!(popupmenu_scope,popupmenu_voltage)
    push!(popupmenu_scope,popupmenu_time)
    push!(popupmenu_scope,popupmenu_thres)
    push!(popupmenu_scope,popupmenu_signal)

    popupmenu_voltage_select=Menu(popupmenu_voltage)
    if VERSION > v"0.7-"
        scope_v_handles=Array{MenuItemLeaf}(undef,0)
    else
        scope_v_handles=Array{MenuItemLeaf}(0)
    end
    voltage_scales = [1, 50, 100, 200, 500]
    push!(scope_v_handles,MenuItem(string(voltage_scales[1])))
    push!(popupmenu_voltage_select,scope_v_handles[1])
    for i=2:5
        push!(scope_v_handles,MenuItem(scope_v_handles[i-1],string(voltage_scales[i])))
        push!(popupmenu_voltage_select,scope_v_handles[i])
    end

    popupmenu_time_select=Menu(popupmenu_time)
    if VERSION > v"0.7-"
        scope_t_handles=Array{MenuItemLeaf}(undef,0)
    else
        scope_t_handles=Array{MenuItemLeaf}(0)
    end
    time_scales = [1,2,3,4,5] #Need to make this ms / div
    for i=1:length(time_scales)
        time_scales[i]=round(time_scales[i],1)
    end
    push!(scope_t_handles,MenuItem(string(time_scales[1])))
    push!(popupmenu_time_select,scope_t_handles[1])
    for i=2:5
        push!(scope_t_handles,MenuItem(scope_t_handles[i-1],string(time_scales[i])))
        push!(popupmenu_time_select,scope_t_handles[i])
    end

    popupmenu_thres_select=Menu(popupmenu_thres)
    if VERSION > v"0.7-"
        scope_thres_handles=Array{MenuItemLeaf}(undef,0)
    else
        scope_thres_handles=Array{MenuItemLeaf}(0)
    end
    push!(scope_thres_handles,MenuItem("On"))
    push!(popupmenu_thres_select,scope_thres_handles[1])
    push!(scope_thres_handles,MenuItem(scope_thres_handles[1],"Off"))
    push!(popupmenu_thres_select,scope_thres_handles[2])

    popupmenu_signal_select=Menu(popupmenu_signal)
    if VERSION > v"0.7-"
        scope_signal_handles=Array{MenuItemLeaf}(undef,0)
    else
        scope_signal_handles=Array{MenuItemLeaf}(0)
    end
    push!(scope_signal_handles,MenuItem("Spike"))
    push!(popupmenu_signal_select,scope_signal_handles[1])
    push!(scope_signal_handles,MenuItem(scope_signal_handles[1],"LFP"))
    push!(popupmenu_signal_select,scope_signal_handles[2])

    Gtk.showall(popupmenu_scope)

    (scope_t_handles,scope_v_handles,scope_thres_handles,scope_signal_handles,popupmenu_scope)
end

function add_scope_callbacks(v_handles,t_handles,thres_handles,signal_handles,handles)

    for i=1:5
        signal_connect(scope_popup_v_cb,v_handles[i],"activate",Void,(),false,(handles,i-1))
    end

    for i=1:5
        signal_connect(scope_popup_t_cb,t_handles[i],"activate",Void,(),false,(handles,i-1))
    end

    for i=1:2
        signal_connect(scope_popup_thres_cb,thres_handles[i],"activate",Void,(),false,(handles,i-1))
    end

    for i=1:2
        signal_connect(scope_popup_signal_cb,signal_handles[i],"activate",Void,(),false,(handles,i-1))
    end

    nothing
end

function scope_popup_v_cb(widgetptr::Ptr,user_data::Tuple{Gui_Handles,Int64})

    han, event_id = user_data

    if event_id==0
        han.soft.v_div=1.0
    elseif event_id==1
        han.soft.v_div=50.0
    elseif event_id==2
        han.soft.v_div=100.0
    elseif event_id==3
        han.soft.v_div=200.0
    elseif event_id==4
        han.soft.v_div=500.0
    end

    han.soft.v_div /= 1000.0

    nothing
end

function scope_popup_t_cb(widgetptr::Ptr,user_data::Tuple{Gui_Handles,Int64})

    han, event_id = user_data

    #=
    500 pixels across and time boxes are 50 pixels
    So if Sample Rate is 30k, then each box is 50/30000 = 1.67 ms
    20k, 50/20000 = 2.5 ms
    =#

    if event_id==0
        han.soft.t_div=1.0
    elseif event_id==1
        han.soft.t_div=2.0
    elseif event_id==2
        han.soft.t_div=3.0
    elseif event_id==3
        han.soft.t_div=4.0
    elseif event_id==4
        han.soft.t_div=5.0
    end

    nothing
end

function scope_popup_thres_cb(w::Ptr,user_data::Tuple{Gui_Handles,Int64})

    han, event_id = user_data

    if event_id==0
        han.soft.thres_on=true
    else
        han.soft.thres_on=false
    end

    nothing
end

function scope_popup_signal_cb(w::Ptr,user_data::Tuple{Gui_Handles,Int64})

    han, event_id = user_data

    if event_id == 0
        han.soft.signal_type=1
    else
        han.soft.signal_type=2
    end

    nothing
end

function draw_scope(rhd::RHD2000,han::Gui_Handles)

    ctx=Gtk.getgc(han.c)
    myheight=height(ctx)

    if han.soft.draws>9

        startind=SAMPLES_PER_DATA_BLOCK*(han.soft.draws-1)+1
        if han.soft.signal_type==1
            for i=1:SAMPLES_PER_DATA_BLOCK
                han.soft.v[startind]=rhd.v[i,han.sc.spike]
                startind+=1
            end
        else
            for i=1:SAMPLES_PER_DATA_BLOCK
                han.soft.v[startind]=rhd.lfps[i,han.sc.spike]
                startind+=1
            end
        end

        #Paint over old line
        move_to(ctx,1.0,han.soft.last[1])
        for i=2:499
            line_to(ctx,i,han.soft.last[i])
        end

        #Paint over old asterisks
        move_to(ctx,1.0,myheight-4.0)
        line_to(ctx,512.0,myheight-4.0)
        move_to(ctx,1.0,myheight-7.0)
        line_to(ctx,512.0,myheight-7.0)

        set_source(ctx,han.soft.ctx)
        set_line_width(ctx,4.0)
        stroke(ctx)

        s=han.soft.v_div*-1

        #Draw voltage trace from desired channel
        move_to(ctx,1.0,myheight-150.0+han.soft.v[1]*s)
        han.soft.last[1]=myheight-150.0+han.soft.v[1]*s

        t_iter=floor(Int64,han.soft.t_div)

        spike_ind=1

        scope_ind=1+t_iter
        for i=2:512
            if spike_ind > 500
                spike_ind = 500
            end
            y=myheight-150.0+han.soft.v[scope_ind]*s
            line_to(ctx,i,y)
            han.soft.last[i]=y

            if scope_ind>han.soft.spikes[spike_ind]
                han.soft.prev_spikes[spike_ind]=i
                spike_ind+=1
            end

            scope_ind+=t_iter
        end
        set_source_rgb(ctx,1.0,1.0,1.0)
        set_line_width(ctx,0.5)
        stroke(ctx)

        #reset spikes
        for i=1:(spike_ind-1)
            move_to(ctx,han.soft.prev_spikes[i],myheight)
            show_text(ctx,"*")
        end
        han.soft.prev_num_spikes=spike_ind-1
        han.soft.num_spikes=0

        #draw threshold

        if han.soft.thres_on
            plot_thres_scope(han,rhd,ctx)
        end

        han.soft.draws=1
    else
        #copy voltage
        startind=SAMPLES_PER_DATA_BLOCK*(han.soft.draws-1)+1

        if han.soft.signal_type==1
            for i=1:SAMPLES_PER_DATA_BLOCK
                han.soft.v[startind]=rhd.v[i,han.sc.spike]
                startind+=1
            end
        else
            for i=1:SAMPLES_PER_DATA_BLOCK
                han.soft.v[startind]=rhd.lfps[i,han.sc.spike]
                startind+=1
            end
        end

        #get spikes
        for g=1:rhd.nums[han.sc.spike]
            han.soft.num_spikes+=1
            han.soft.spikes[han.soft.num_spikes]=rhd.buf[g,han.sc.spike].inds.start+SAMPLES_PER_DATA_BLOCK*(han.soft.draws-1)+1
        end

        han.soft.draws+=1
    end

    nothing
end

function plot_thres_scope(han,rhd,ctx)

    myheight=height(ctx)

    thres=han.sc.thres*han.soft.v_div

    move_to(ctx,1,myheight-150-thres+2)
    line_to(ctx,500,myheight-150-thres+2)

    move_to(ctx,1,myheight-150-thres-2)
    line_to(ctx,500,myheight-150-thres-2)

    set_line_width(ctx,5.0)
    set_source_rgb(ctx,0.0,0.0,0.0)
    stroke(ctx)

    move_to(ctx,1,myheight-150-thres)
    line_to(ctx,500,myheight-150-thres)
    set_line_width(ctx,1.0)
    set_source_rgb(ctx,1.0,1.0,1.0)
    stroke(ctx)

    nothing
end
