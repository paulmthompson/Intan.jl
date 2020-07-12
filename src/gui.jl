
if Sys.iswindows()
    const glade_path = string(dirname(Base.source_path()),"\\interface.glade")
else
    const glade_path = string(dirname(Base.source_path()),"/interface.glade")
end

function makegui(r::RHD2000,s,task,fpga)

    b = Builder(filename=glade_path)

    #GUI ARRANGEMENT
    grid = Grid()

    #COLUMN 1 - control buttons

    #ROW 1

    #ROW 2
    vbox1_2=Grid()
    scroll_left=ScrolledWindow()
    Gtk.GAccessor.policy(scroll_left,Gtk.GConstants.GtkPolicyType.NEVER,Gtk.GConstants.GtkPolicyType.AUTOMATIC)
    push!(scroll_left,vbox1_2)
    grid[1,2]=scroll_left

    frame_control=Frame("Control")
    grid[1,1]=frame_control
    vbox_control = Grid()
    push!(frame_control,vbox_control)

    button_init = Button()
    add_button_label(button_init,"Init")
    vbox_control[1,1]=button_init

    button_run = ToggleButton()
    add_button_label(button_run,"Run")
    vbox_control[2,1]=button_run

    button_record = ToggleButton()
    add_button_label(button_record,"Record")
    vbox_control[3,1]=button_record

    #GAIN
    frame1_2=Frame("Gain")
    vbox1_2[1,2]=frame1_2
    vbox1_2_1=Grid()
    push!(frame1_2,vbox1_2_1)

    sb2=SpinButton(1:1000)
    Gtk.GAccessor.value(sb2,1)
    vbox1_2_1[1,1]=sb2

    gain_checkbox=CheckButton()
    add_button_label(gain_checkbox," x 10")
    vbox1_2_1[2,1]=gain_checkbox

    button_gain = CheckButton()
    add_button_label(button_gain,"All Channels")
    Gtk.GAccessor.active(button_gain,false)
    vbox1_2_1[1,2]=button_gain

    #THRESHOLD
    (thres_widgets,frame1_3,vbox_slider)=_make_thres_gui()
    vbox1_2[1,3]=frame1_3

    #SPIKE
    frame_hold=Frame("Spike")
    vbox1_2[1,4]=frame_hold
    vbox_hold=Grid()
    push!(frame_hold,vbox_hold)

    button_pause=ToggleButton()
    add_button_label(button_pause,"Pause")
    vbox_hold[2,2]=button_pause

    button_clear=Button()
    add_button_label(button_clear,"Refresh")
    vbox_hold[1,2]=button_clear

    button_restore=Button()
    add_button_label(button_restore,"Restore")
    vbox_hold[3,2]=button_restore

    if VERSION > v"0.7-"
        button_rb=Array{RadioButton}(undef, 3)
    else
        button_rb=Array{RadioButton}(3)
    end
    button_rb[1]=RadioButton(active=true)
    button_rb[2]=RadioButton(button_rb[1])
    button_rb[3]=RadioButton(button_rb[2])

    vbox_hold[1,3]=button_rb[1]
    Gtk.GAccessor.mode(button_rb[1],false)
    add_button_label(button_rb[1],"RubberBand")
    vbox_hold[2,3]=button_rb[2]
    Gtk.GAccessor.mode(button_rb[2],false)
    add_button_label(button_rb[2],"Draw")
    vbox_hold[3,3]=button_rb[3]
    Gtk.GAccessor.mode(button_rb[3],false)
    add_button_label(button_rb[3],"Selection")

    #CLUSTER
    frame1_4=Frame("Clustering")

    vbox1_3_2=Grid()
    push!(frame1_4,vbox1_3_2)

    button_sort1 = Button()
    button_sort2 = Button()
    button_sort3 = Button()

    button_sort4 = ToggleButton()
    button_sort5 = Button()

    check_sort1 = CheckButton()

    slider_sort = Scale(false, 0.0, 2.0,.02)
    adj_sort = Adjustment(slider_sort)
    Gtk.GAccessor.value(adj_sort,1.0)
    slider_sort_label=Label("Slider Label")

    sort_list=ListStore(Int32)
    push!(sort_list,(0,))
    sort_tv=TreeView(TreeModel(sort_list))
    sort_r1=CellRendererText()
    sort_c1=TreeViewColumn("Cluster",sort_r1, Dict([("text",0)]))
    Gtk.GAccessor.activate_on_single_click(sort_tv,1)

    push!(sort_tv,sort_c1)

    vbox1_3_2[1,3] = button_sort1
    vbox1_3_2[1,4] = button_sort2
    vbox1_3_2[1,5] = button_sort3
    vbox1_3_2[1,6] = button_sort4
    vbox1_3_2[1,7] = check_sort1
    #vbox1_3_2[1,7]=button_sort5
    vbox1_3_2[1,8] = slider_sort
    vbox1_3_2[1,9] = slider_sort_label

    myscroll=ScrolledWindow()
    Gtk.GAccessor.min_content_height(myscroll,150)
    Gtk.GAccessor.min_content_width(myscroll,100)
    push!(myscroll,sort_tv)
    vbox1_3_2[1,10]=myscroll
    vbox1_3_2[1,11]=Canvas(180,10)

    vbox1_2[1,5]=frame1_4 |> Gtk.showall

    #COLUMN 2 - Threshold slider

    grid[3,2]=vbox_slider


    #COLUMN 3 - MAXIMIZED CHANNEL PLOTTING

    #ROW 2
    c_grid=Grid()

    c2=Canvas()

    @guarded draw(c2) do widget
        ctx = Gtk.getgc(c2)
        SpikeSorting.clear_c2(c2,1)
    end

    show(c2)
    c_grid[1,1]=c2
    Gtk.GAccessor.hexpand(c2,true)
    Gtk.GAccessor.vexpand(c2,true)

    #ROW 2
    c3=Canvas(-1,200)
    @guarded draw(c3) do widget
        ctx = Gtk.getgc(c3)
        SpikeSorting.clear_c3(c3,1)
    end
    show(c3)
    c_grid[1,2]=c3
    Gtk.GAccessor.hexpand(c3,true)

    grid[4,2]=c_grid

    #ROW 3
    c2_slider=Scale(false, 1:16)
    adj2 = Adjustment(c2_slider)
    Gtk.GAccessor.value(adj2,1)
    grid[4,3]=c2_slider

    #COLUMN 3 - 16 CHANNEL DISPLAY

    #ROW 1 - Time
    (mytime_widgets,frame_time) = _make_clock()
    grid[5,1]=frame_time

    #ROW 2
#c=@Canvas(500,800)
c=Canvas(500)
    @guarded draw(c) do widget
        ctx = Gtk.getgc(c)
        set_source_rgb(ctx,0.0,0.0,0.0)
        set_operator(ctx,Cairo.OPERATOR_SOURCE)
        paint(ctx)
    end
    show(c)
grid[5,2]=c
    Gtk.GAccessor.vexpand(c,true)

    #ROW 3
    #Which 16 channels can be selected with a slider
    c_slider = Scale(false, 0:(div(length(r.nums)-1,16)+1))
    adj = Adjustment(c_slider)
    Gtk.GAccessor.value(adj,1)
    grid[5,3]=c_slider

    #COLUMN 4
    #ROW 2
    vbox_42=Box(:v)
    grid[6,2]=vbox_42

vbox_rb_upper=Box(:v)
    push!(vbox_42,vbox_rb_upper)

    push!(vbox_rb_upper,Label("Top Panel"))

    if VERSION > v"0.7-"
        rbs=Array{RadioButton}(undef,5)
    else
        rbs=Array{RadioButton}(5)
    end
    rbs[1]=RadioButton("16 Channel",active=true)
    rbs[2]=RadioButton(rbs[1],"32 Channel")
    rbs[3]=RadioButton(rbs[2],"64 Channel")
    rbs[4]=RadioButton(rbs[3],"64 Raster")
    rbs[5]=RadioButton(rbs[4],"Blank")

    push!(vbox_rb_upper,rbs[1])
    push!(vbox_rb_upper,rbs[2])
    push!(vbox_rb_upper,rbs[3])
    push!(vbox_rb_upper,rbs[4])
    push!(vbox_rb_upper,rbs[5])

c_rb=Canvas(40)
Gtk.GAccessor.vexpand(c_rb,true)

    push!(vbox_42,c_rb)

    vbox_rb_lower=Box(:v)
    push!(vbox_42,vbox_rb_lower)
    push!(vbox_rb_lower,Label("Lower Panel"))

    if VERSION > v"0.7-"
        rbs2=Array{RadioButton}(undef,8)
    else
        rbs2=Array{RadioButton}(8)
    end
    rbs2[1]=RadioButton("Events",active=true)
    rbs2[2]=RadioButton(rbs2[1],"16 Raster")
    rbs2[3]=RadioButton(rbs2[2],"32 Raster")
    rbs2[4]=RadioButton(rbs2[3],"Soft Scope")
rbs2[5]=RadioButton(rbs2[4],"64 Channel")
rbs2[6]=RadioButton(rbs2[5],"64 Raster")
rbs2[7]=RadioButton(rbs2[6],"Spectrogram")
rbs2[8]=RadioButton(rbs2[7],"Nothing")

    push!(vbox_rb_lower,rbs2[1])
    push!(vbox_rb_lower,rbs2[2])
    push!(vbox_rb_lower,rbs2[3])
    push!(vbox_rb_lower,rbs2[4])
    push!(vbox_rb_lower,rbs2[5])
    push!(vbox_rb_lower,rbs2[6])
push!(vbox_rb_lower,rbs2[7])
push!(vbox_rb_lower,rbs2[8])

    #MENU ITEMS

    #SORTING
    sortopts = MenuItem("_File")
    sortmenu = Menu(sortopts)
    load_sort_ = MenuItem("Load Sorting Parameters")
    push!(sortmenu,load_sort_)
    save_sort_ = MenuItem("Save Sorting Parameters")
push!(sortmenu,save_sort_)
load_backup_ = MenuItem("Recover Parameters from Backup")
push!(sortmenu,load_backup_)

saving_pref_=MenuItem("Saving Preferences")
push!(sortmenu,saving_pref_)

#Export

exopts = MenuItem("_Export")
push!(sortmenu,exopts)
    exmenu = Menu(exopts)
    export_plex_ = MenuItem("Plexon")
    push!(exmenu,export_plex_)
    export_klusta_ = MenuItem("KlustaFormat")
    push!(exmenu,export_klusta_)
    export_nwb_ = MenuItem("NWB")
    push!(exmenu,export_nwb_)
    export_jld_ = MenuItem("JLD")
    push!(exmenu,export_jld_)
export_mat_ = MenuItem("MAT")
push!(exmenu,export_mat_)

viewopts = MenuItem("_View")
viewmenu = Menu(viewopts)

    define_ref_ = MenuItem("Reference Configuration")
push!(viewmenu,define_ref_)

define_params = MenuItem("Parameter Table")
push!(viewmenu,define_params)

sv_open = MenuItem("Sort Viewer")
push!(viewmenu,sv_open)

define_ttls_ = MenuItem("TTL Configuration")
push!(viewmenu,define_ttls_)

#Options
opopts = MenuItem("_Options")
opmenu = Menu(opopts)

op_align = MenuItem("Alignment")
push!(opmenu,op_align)
op_align_menu = Menu(op_align)
op_align_min = MenuItem("Minimum")
push!(op_align_menu,op_align_min)
op_align_cross = MenuItem("Threshold Crossing")
push!(op_align_menu,op_align_cross)

op_band = MenuItem("Bandwidth")
push!(opmenu,op_band)

    mb = MenuBar()
    push!(mb,sortopts)
push!(mb,viewopts)
push!(mb,opopts)
grid[4,1]=mb


#SortView

sortview_handles = SpikeSorting.sort_gui(s[1].s.win+1)
visible(sortview_handles.win,false)


#POPUP MENUS

#Enable-Disable
    popupmenu = Menu()
    popup_enable = MenuItem("Enable")
    push!(popupmenu, popup_enable)
    popup_disable = MenuItem("Disable")
    push!(popupmenu, popup_disable)
Gtk.showall(popupmenu)

#Event
(event_handles,popup_event,popup_event_none) = _make_event_gui()

    setproperty!(grid, :column_spacing, 15)
    setproperty!(grid, :row_spacing, 15)
win = Window(grid, "Intan.jl GUI") |> Gtk.showall


#Spectrogram Menus
(spect_w_handles,spect_f_handles, popupmenu_spect) = _make_spectogram_gui()


#Soft Scope Menus
(scope_t_handles,scope_v_handles,scope_thres_handles,scope_signal_handles,popupmenu_scope) = _make_scope_gui()

prepare_save_folder(r)

    #Callback functions that interact with canvas depend on spike sorting method that is being used

    scales=ones(Float64,size(r.v,2),2) .* -.125
    scales[:,2]=scales[:,2].*.25
offs=zeros(Int64,size(r.v,2))

scope_mat=ones(Float64,500,3)

for i=1:500
    scope_mat[i,1]=550.0
    scope_mat[i,2]=650.0
    scope_mat[i,3]=750.0
end

sort_widgets=Sort_Widgets(button_sort1,button_sort2,button_sort3,button_sort4,check_sort1,false)

gain_widgets=SpikeSorting.Gain_Widgets(sb2,gain_checkbox,button_gain)
spike_widgets=Spike_Widgets(button_clear,button_pause)

#Make Filter Menu
band_widgets=_make_filter_gui()
band_widgets.lfp_en=falses(size(r.v,2))
setproperty!(band_widgets.sw_chan_sb,:upper,size(r.v,2))

#Make Table Menu
table_widgets=_make_table_gui()
for i=1:size(r.v,2)
    push!(table_widgets.list,(i,125,0,0,true))
end

#Reference Menu
ref_widgets = _make_reference_gui()
for i=1:size(r.v,2)
    push!(ref_widgets.list1,(i,))
    push!(ref_widgets.list2,(i,))
end

spect_widgets=Spectrogram(r.sr)

save_widgets=_make_save_gui()
Gtk.GAccessor.text(save_widgets.input,r.save.folder)

sleep(5.0)

sc_widgets=SpikeSorting.Single_Channel(c2,c3,Gtk.getgc(c2),copy(Gtk.getgc(c2)),false,RubberBand(Vec2(0.0,0.0),
Vec2(0.0,0.0),Vec2(0.0,0.0),[Vec2(0.0,0.0)],false,0),1,falses(500),falses(500),
false,false,button_pause,button_rb,1,(0.0,0.0),false,width(Gtk.getgc(c2)),
    height(Gtk.getgc(c2)),s[1].s.win,1.0,0.0,sortview_handles.buf,0.0,0.0,
    ClusterTemplate(convert(Int64,s[1].s.win)),0,1,false,sort_list,sort_tv,adj_sort,thres_widgets.adj,thres_widgets.slider,false,
    thres_widgets,gain_widgets)

    #Create type with handles to everything
handles=Gui_Handles(win,button_run,button_init,button_record,c_slider,adj,c2_slider,adj2,
                    c,1,1,scales,offs,(0.0,0.0),zeros(Int64,length(r.nums)),
                    0,-1 .*ones(Int64,6),
                    trues(length(r.nums)),mytime_widgets,
                    s[1].s.win,1,1,popupmenu,popup_event,popupmenu_spect,rbs,rbs2,scope_mat,
                    false,16,
                    false,slider_sort,
                    1,1,zeros(Int64,500),zeros(UInt32,20),
                    zeros(UInt32,500),zeros(Int64,50),SoftScope(r.sr,Gtk.getgc(c),SAMPLES_PER_DATA_BLOCK),
                    popupmenu_scope,sort_widgets,spike_widgets,
                    sortview_handles,band_widgets,table_widgets,spect_widgets,save_widgets,ref_widgets,
                    b,sc_widgets,sortview_handles.buf,rand(Int8,r.sr))

    handles.sc.s = -.125

Gtk.GAccessor.value(sb2,round(Int,scales[1,1]*-1000))


#=
Template Sorting Callbacks
=#

    id = signal_connect(SpikeSorting.canvas_release_template,c2,"button-release-event",Void,(Ptr{Gtk.GdkEventButton},),false,(sortview_handles.buf,sc_widgets))

    id = signal_connect(SpikeSorting.b1_cb_template,button_sort1,"clicked",Void,(),false,(sc_widgets,))
    add_button_label(button_sort1,"Delete Unit")

    id = signal_connect(SpikeSorting.b2_cb_template,button_sort2,"clicked",Void,(),false,(sc_widgets,))
    add_button_label(button_sort2,"Add Unit")

    id = signal_connect(SpikeSorting.b3_cb_template,button_sort3,"clicked",Void,(),false,(sc_widgets,sortview_handles))
    add_button_label(button_sort3,"Collect Templates")

    id = signal_connect(SpikeSorting.b4_cb_template,button_sort4,"clicked",Void,(),false,(sc_widgets,))
    add_button_label(button_sort4,"Show Template Bounds")

    setproperty!(check_sort1,:label,"Show Template")
    id = signal_connect(SpikeSorting.check_cb_template,check_sort1,"clicked",Void,(),false,(sc_widgets,))

    setproperty!(slider_sort_label,:label,"Tolerance")

id = signal_connect(SpikeSorting.unit_select_cb,sort_tv, "row-activated", Void, (Ptr{Gtk.GtkTreePath},Ptr{Gtk.GtkTreeViewColumn}), false, (handles.sc,))
id = signal_connect(SpikeSorting.canvas_press_win,c2,"button-press-event",Void,(Ptr{Gtk.GdkEventButton},),false,(handles.sc,))


#=
Window Callbacks
=#

id = signal_connect(SpikeSorting.win_resize_cb, win, "size-allocate",Void,(Ptr{Gtk.GdkRectangle},),false,(sc_widgets,))
id = signal_connect(close_cb,win, "destroy",Void,(),false,(handles,r,fpga))

#=
ISI canvas callbacks
=#
id = signal_connect(SpikeSorting.c3_press_win,c3,"button-press-event",Void,(Ptr{Gtk.GdkEventButton},),false,(sc_widgets,))


#=
Start Button Callbacks
=#

    id = signal_connect(run_cb, button_run, "clicked",Void,(),false,(handles,r,s,task,fpga))
    id = signal_connect(init_cb, button_init, "clicked", Void, (), false, (handles,r,task,fpga))
    id = signal_connect(record_cb,button_record,"clicked",Void,(),false,(handles,r))

#=
Slider callbacks
=#

    id = signal_connect(update_c1, c_slider, "value-changed", Void, (), false, (handles,))
id = signal_connect(update_c2_cb, c2_slider, "value-changed", Void, (), false, (handles,))


#=
Enable/Disable callbacks
=#

id = signal_connect(c_popup_select,c,"button-press-event",Void,(Ptr{Gtk.GdkEventButton},),false,(handles,))
id = signal_connect(popup_enable_cb,popup_enable,"activate",Void,(),false,(handles,r))
id = signal_connect(popup_disable_cb,popup_disable,"activate",Void,(),false,(handles,r))


#=
Save Load Callbacks
=#

id = signal_connect(export_plex_cb, export_plex_, "activate",Void,(),false,(handles,r))
id = signal_connect(export_jld_cb, export_jld_, "activate",Void,(),false,(handles,r))
id = signal_connect(export_mat_cb, export_mat_, "activate",Void,(),false,(handles,r))
id = signal_connect(save_config_cb, save_sort_, "activate",Void,(),false,(handles,r,s))
id = signal_connect(load_config_cb, load_sort_, "activate",Void,(),false,(handles,r,s))
id = signal_connect(load_backup_cb, load_backup_, "activate",Void,(),false,(handles,r,s))


#=
Sort Slider Callbacks
=#

id = signal_connect(template_slider, slider_sort, "value-changed", Void, (), false, (handles,))
id = signal_connect(slider_release_template,slider_sort,"button-release-event",Void,(Ptr{Gtk.GdkEventButton},),false,(handles,))


#=
Gain Callbacks
=#

id = signal_connect(sb2_cb,sb2, "value-changed",Void,(),false,(handles,r))
id = signal_connect(SpikeSorting.gain_check_cb,gain_checkbox, "clicked", Void,(),false,(sc_widgets,))


#=
Threshold callbacks
=#

add_thres_cb(sc_widgets)

#=
Pause, Restore, and Clear Callbacks
=#

id = signal_connect(SpikeSorting.pause_cb,button_pause,"toggled",Void,(),false,(handles.sc,))
id = signal_connect(SpikeSorting.clear_button_cb,button_clear,"clicked",Void,(),false,(handles.sc,))
id = signal_connect(SpikeSorting.restore_button_cb,button_restore,"clicked",Void,(),false,(handles.sc,))

#=
Rubberband, Draw, Stretch
=#

for i=1:3
    id = signal_connect(SpikeSorting.pause_state_cb,button_rb[i],"clicked",Void,(),false,(handles.sc,i))
end


#Event Viewer Callbacks
add_event_callbacks(event_handles,popup_event_none,handles)

#=
Radiobutton Callback
=#

for i=1:5
    id = signal_connect(rb1_cb,rbs[i],"clicked",Void,(),false,(handles,i))
end

for i=1:8
    id = signal_connect(rb2_cb,rbs2[i],"clicked",Void,(),false,(handles,i))
end

#=
Save Preferences Callbacks
=#

signal_connect(saving_pref_cb,saving_pref_,"activate",Void,(),false,(handles,r))
add_save_callbacks(save_widgets,handles,r,fpga)

#Soft Scope Callbacks
add_scope_callbacks(scope_v_handles,scope_t_handles,scope_thres_handles,scope_signal_handles,handles)

#Spectrogram Callbacks
add_spect_callbacks(spect_f_handles,spect_w_handles,handles)

#Filtering
signal_connect(band_adj_cb, op_band, "activate",Void,(),false,(handles,r))
add_filter_callbacks(band_widgets,handles,r,fpga)

#Reference
signal_connect(ref_cb, define_ref_, "activate",Void,(),false,(handles,r))
add_reference_callbacks(ref_widgets,handles,r,fpga)

#Parameter Table
signal_connect(table_cb, define_params, "activate",Void,(),false,(handles,r))
add_parameter_callbacks(table_widgets,handles,r,fpga)

signal_connect(ttl_cb,define_ttls_,"activate",Void,(),false,(handles,r))

#=
Sortview Callbacks
=#

id = signal_connect(sv_open_cb, sv_open, "activate",Void,(),false,(handles,))

signal_connect(sortview_handles.win, :delete_event) do widget, event
    visible(sortview_handles.win, false)
    true
end

#=
Backup
=#
f=open(string(r.save.backup,"enabled.bin"),"w")
write(f,handles.enabled)
close(f)

resize!(handles.win,1200,800)

handles
end

#Drawing
function run_cb(widgetptr::Ptr,user_data::Tuple{Gui_Handles,RHD2000,DArray{T,1,Array{T,1}},Task,DArray{I,1,Array{I,1}}}) where {T<:Sorting,I<:IC}

    widget = convert(ToggleButton, widgetptr)

    @async if getproperty(widget,:active,Bool)==true

        #unpack tuple
        han, rhd, s,task,fpga = user_data

	if rhd.debug.state==false
            map(runBoard,fpga)
        end
        while getproperty(widget,:active,Bool)==true
           main_loop_par(rhd,han,s,task,fpga)
        end
    end
    nothing
end

function run_cb(widgetptr::Ptr,user_data::Tuple{Gui_Handles,R,Array{S,1},T,Array{I,1}}) where {R<:RHD2000,S<:Sorting,T<:Task,I<:IC}

    widget = convert(ToggleButton, widgetptr)

    @async if getproperty(widget,:active,Bool)==true

        #unpack tuple
        han, rhd, s,task,fpga = user_data

	if rhd.debug.state==false
            map(runBoard,fpga)
        end
        while getproperty(widget,:active,Bool)==true
           main_loop_s(rhd,han,s,task,fpga)
        end
    end

    nothing
end

function main_loop_s(rhd::RHD2000,han::Gui_Handles,s::Array{T,1},task::Task,fpga::Array{I,1}) where {T<:Sorting, I<:IC}
    if rhd.debug.state==false
        myread=readDataBlocks(rhd,1,s,fpga)
    else
        myread=readDataBlocks(rhd,s)
    end
    main_loop(rhd,han,s,task,myread,fpga)
end

function main_loop_par(rhd::RHD2000,han::Gui_Handles,s::DArray{T,1,Array{T,1}},task::Task,fpga::DArray{I,1,Array{I,1}}) where {T<:Sorting, I<:IC}
    if rhd.debug.state==false
        if rhd.cal<3
            calibrate_parallel(fpga,s,rhd.v,rhd.buf,rhd.nums,rhd.time,rhd.cal)
        else
            onlinesort_parallel(fpga,s,rhd.v,rhd.buf,rhd.nums,rhd.time)
        end
        cal_update(rhd)
	myread=true
    else
        myread=readDataBlocks(rhd,s)
    end
    main_loop(rhd,han,s,task,myread,fpga)
end

function main_loop(rhd::RHD2000,han::Gui_Handles,s,task::Task,myread::Bool,fpga)

    #process and output (e.g. kalman, spike triggered stim calc, etc)
    do_task(task,rhd,myread,han,fpga)

    #plot spikes
    if myread
	if han.num16>0

            #top right
            if han.c_right_top==1
                draw_spike16(rhd,han)
            elseif han.c_right_top==2
                draw_spike32(rhd,han)
            elseif han.c_right_top==3
		draw_spike64(rhd,han)
            elseif han.c_right_top==4
            elseif han.c_right_top==5
            else
            end

            #bottom right
            if han.c_right_bottom==1
	        plot_events(fpga,han,han.draws)
            elseif han.c_right_bottom==2
                draw_raster16(rhd,han)
            elseif han.c_right_bottom==3
                draw_raster32(rhd,han)
            elseif han.c_right_bottom==4
                draw_scope(rhd,han)
            elseif han.c_right_bottom==5
		        draw_spike64(rhd,han)
            elseif han.c_right_bottom==6
                draw_raster64(rhd,han)
            elseif han.c_right_bottom==7
                draw_spectrogram(rhd,han)
            else
            end

            update_time(rhd,han)
	        reveal(han.c)

            if han.spike_changed
                new_single_channel(han,rhd,s,fpga)

                #Clear Sortview
            end
            if han.buf.c_changed

                clus = han.buf.selected_clus

                if clus>0

                    #Find Cluster characteristics from selected waveforms
                    (mymean,mystd)=SpikeSorting.make_cluster(han.buf.spikes,han.buf.mask,han.buf.ind,.!han.buf.selected)

                    #Apply cluster characteristics to handles cluster
                    SpikeSorting.change_cluster(han.sc.temp,mymean,mystd,clus)
                    setproperty!(han.sc.adj_sort, :value, 1.0)

                    if (han.buf.count>0)&(han.sc.pause)
                        SpikeSorting.template_cluster(han.sc,clus,mymean,mystd[:,2],mystd[:,1],1.0)
                    end

                end

                #Send cluster information to sorting
                SpikeSorting.send_clus(s,han.sc)
                backup_clus(han.sc.temp,han.sc.spike,rhd.save.backup)
                han.buf.c_changed=false
            end
            if han.buf.replot
                SpikeSorting.replot_all_spikes(han.sc)
                if visible(han.sortview_widgets.win)
                    if !han.sc.pause

                    else
                        #Refresh Screen
                        SpikeSorting.replot_sort(han.sortview_widgets)
                    end
                end
                han.buf.replot=false
            end
	    if (han.num>0)&(!han.sc.pause)
		   draw_spike(rhd,han)
	    end
            if han.sc.thres_changed
                thres_changed(han,s,fpga,rhd.save.backup)
            end
            if han.sc.show_thres
                SpikeSorting.plot_thres(han.sc)
            end
            if han.sc.rb_active
                SpikeSorting.draw_rb(han.sc)
            end
            draw_c3(rhd,han)
	end
	han.draws+=1
	if han.draws>500
	    han.draws=0
            if han.num16>0
	        clear_c(han)
            end
            if (!han.sc.hold)&(!han.sc.pause)
	            SpikeSorting.clear_c2(han.sc.c2,han.sc.spike)
                han.sc.ctx2=Gtk.getgc(han.sc.c2)
                han.sc.ctx2s=copy(han.sc.ctx2)
            end
            SpikeSorting.clear_c3(han.sc.c3,han.sc.spike)
            #Sort Button
            if han.sc.sort_cb
                SpikeSorting.draw_templates(han.sc)
            end
	end
        reveal(han.sc.c2)
        reveal(han.sc.c3)
	#write to disk, clear buffers
        queueToFile(rhd,task,fpga)
    end
    sleep(.00001)
    #sleep(.02) #debug
    nothing
end

function update_c1(widget::Ptr,user_data::Tuple{Gui_Handles})

    han, = user_data
    han.num16=getproperty(han.adj,:value,Int64) # 16 channels

    if han.num16>0
        clear_c(han)
        han.spike_changed=true
    end
    nothing
end

update_c2_cb(w::Ptr,d::Tuple{Gui_Handles})=update_c2(d[1])

function update_c2(han::Gui_Handles)

    han.num=getproperty(han.adj2, :value, Int64) # primary display

    if han.num16>0

        old_spike=rem(han.sc.spike-1,han.chan_per_display)+1
        han.spike_changed=true

        #Highlight channel
        highlight_channel(han,old_spike)
    end
    nothing
end

function get_cluster(han::Gui_Handles,s::Array{T,1}) where T<:Sorting
    han.sc.temp=deepcopy(s[han.sc.spike].c)
end

function get_cluster(han::Gui_Handles,s::DArray{T,1,Array{T,1}}) where T<:Sorting
    (nn,mycore)=get_thres_id(s,han.sc.spike)

    han.sc.temp=remotecall_fetch(((x,ss)->localpart(x)[ss].c),mycore,s,nn)
end

function backup_clus(myclus,chan,backup)

    f=open(string(backup,"/cluster/",chan,".bin"),"w")
    for i in fieldnames(typeof(myclus))
        write(f,getfield(myclus,i))
    end
    close(f)

    nothing
end

function init_cb(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000,Task,Array{I,1}}) where I<:IC

    han, rhd,task,fpga = user_data
    if !rhd.initialized
        init_board!(rhd,fpga)
        init_task(task,rhd,han,fpga)
        rhd.initialized=true
    end

    nothing
end

function init_cb(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000,Task,DArray{I,1,Array{I,1}}}) where I<:IC

    han, rhd,task,fpga = user_data
    if !rhd.initialized
        init_board!(rhd,fpga)
        init_task(task,rhd,han,fpga)
        rhd.initialized=true
    end

    nothing
end

function record_cb(widgetptr::Ptr, user_data::Tuple{Gui_Handles,R}) where R<:RHD2000

    han, rhd = user_data

    widget = convert(ToggleButton, widgetptr)

    if getproperty(widget,:active,Bool)
        rhd.save.record_mode = true
    else
        sleep(1.0)
        rhd.save.record_mode = false
    end
    nothing
end

#=
SortView Callbacks
=#

function sv_open_cb(widget::Ptr,user_data::Tuple{Gui_Handles})

    han, = user_data
    visible(han.sortview_widgets.win,true)
    nothing
end


#=
Right Canvas Callbacks
=#

function c_popup_select(widget::Ptr,param_tuple,user_data::Tuple{Gui_Handles})

    han, = user_data
    event = unsafe_load(param_tuple)

    ctx=Gtk.getgc(han.c)
    myheight=height(ctx)

    han.mim=(event.x,event.y)

    if event.y<(myheight-300) #top

        if han.c_right_top==1 #disable enable 16

            if event.button == 1 #left click

                (inmulti,channel_num)=check_multi(han,4,4,16,event.x,event.y)

                if inmulti
                    Gtk.GAccessor.value(han.adj2,channel_num)
                    update_c2(han)
                end

            elseif event.button == 3 #right click

                popup(han.popup_ed,event)
            end
        elseif han.c_right_top==2 #disable enable 32

            if event.button == 1 #left click

                (inmulti,channel_num)=check_multi(han,6,6,32,event.x,event.y)
                if inmulti
                    Gtk.GAccessor.value(han.adj2,channel_num)
                    update_c2(han)
                end

            elseif event.button == 3 #right click

                popup(han.popup_ed,event)
            end

        elseif han.c_right_top==3 #disable enable 64

            if event.button == 1 #left click

                (inmulti,channel_num)=check_multi(han,11,6,64,event.x,event.y)
                if inmulti
                    Gtk.GAccessor.value(han.adj2,channel_num)
                    update_c2(han)
                end

            elseif event.button == 3 #right click

                popup(han.popup_ed,event)
            end

        elseif han.c_right_top==4 #64 channel raster - nothing
        else
        end
    else #bottom

        if han.c_right_bottom==1 #event select

            if event.button ==3 #right click
                popup(han.popup_event,event)
            end

        elseif han.c_right_bottom==2 #16 raster - nothing
        elseif han.c_right_bottom==3 #32 raster - nothing
        elseif han.c_right_bottom==4 #select scope channels

            if event.button == 3 #right click
                popup(han.popup_scope,event)
            end

        elseif han.c_right_bottom==5 #disable enable 64

            if event.button == 1 #left click

                (inmulti,channel_num)=check_multi(han,11,6,64,event.x,event.y)
                if inmulti
                    Gtk.GAccessor.value(han.adj2,channel_num)
                    update_c2(han)
                end

            elseif event.button == 3 #right click

                popup(han.popup_ed,event)
            end

        elseif han.c_right_bottom==6 #64 channel raster - nothing
        elseif han.c_right_bottom==7 #spectrogram

            if event.button == 3 #right click
                popup(han.popup_spect,event)
            end

        else

        end
    end
    nothing
end

function check_multi(han::Gui_Handles,n_row::Int64,n_col::Int64,num_chan::Int64,x,y)

    (xbounds,ybounds)=get_multi_bounds(han,n_col,n_row,num_chan)

    count=1
    inmulti=false
    for j=2:length(xbounds), i=2:length(ybounds)
        if (x<xbounds[j])&(y<ybounds[i])
            inmulti=true
            break
        end
        count+=1
    end

    (inmulti,count)
end

function get_multi_bounds(han::Gui_Handles,n_col,n_row,num_chan)

    ctx=Gtk.getgc(han.c)

    mywidth=width(ctx)
    if num_chan<64
        myheight=height(ctx)-300.0
    else
        myheight=height(ctx)
    end

    xbounds=linspace(0.0,mywidth,n_col+1)
    ybounds=linspace(0.0,myheight,n_row+1)

    (xbounds,ybounds)
end

function get_multi_dims(han::Gui_Handles,n_col,n_row,num_chan,spike)

    (xbounds,ybounds)=get_multi_bounds(han,n_col,n_row,num_chan)

    y=rem(rem(spike-1,num_chan),n_row)+1
    x=div(rem(spike-1,num_chan),n_row)+1

    (xbounds[x],xbounds[x+1],ybounds[y],ybounds[y+1])
end

#(handles,r,fpga))
function close_cb(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000,Array{I,1}}) where I<:IC

    han, rhd, fpgas = user_data

    #If we were in run loop, turn off

    for i=1:length(fpgas)
        resetBoard(fpgas[i])
        if (OPEN_EPHYS)
            enableBoardLeds(fpgas[i],false)
        end
    end

    println("Bye!")

    nothing
end
