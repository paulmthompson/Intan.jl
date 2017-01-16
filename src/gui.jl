

function makegui(r::RHD2000)

    #GUI ARRANGEMENT
    grid = @Grid()

    #COLUMN 1 - control buttons
	
    #ROW 1
	
    #ROW 2
    vbox1_2=@Grid()
    grid[1,2]=vbox1_2
	
    frame_control=@Frame("Control")
    grid[1,1]=frame_control
    vbox_control = @Grid()
    push!(frame_control,vbox_control)
    
    button_init = @Button()
    add_button_label(button_init,"Init")
    vbox_control[1,1]=button_init
    
    button_run = @ToggleButton()
    add_button_label(button_run,"Run")
    vbox_control[2,1]=button_run
    
    button_cal = @CheckButton("Calibrate")
    setproperty!(button_cal,:active,true)
    vbox_control[1,2]=button_cal

    #GAIN
    frame1_2=@Frame("Gain")
    vbox1_2[1,2]=frame1_2
    vbox1_2_1=@Box(:v)
    push!(frame1_2,vbox1_2_1)

    sb2=@SpinButton(1:1000)
    setproperty!(sb2,:value,1)
    push!(vbox1_2_1,sb2)

    gain_checkbox=@CheckButton()
    add_button_label(gain_checkbox," x 10")
    push!(vbox1_2_1,gain_checkbox)

    sb_offset=@SpinButton(-1000:1000)
    setproperty!(sb_offset,:value,0)

    button_gain = @CheckButton()
    add_button_label(button_gain,"All Channels")
    setproperty!(button_gain,:active,false)
    push!(vbox1_2_1,button_gain)
    
		
    #THRESHOLD
    frame1_3=@Frame("Threshold")
    vbox1_2[1,3]=frame1_3
    vbox1_3_1=@Box(:v)
    push!(frame1_3,vbox1_3_1)
    
    sb=@SpinButton(-300:300)
    setproperty!(sb,:value,0)
    push!(vbox1_3_1,sb)

    button_thres_all = @CheckButton()
    add_button_label(button_thres_all,"All Channels")
    setproperty!(button_thres_all,:active,false)
    push!(vbox1_3_1,button_thres_all)
    
    button_thres = @CheckButton()
    add_button_label(button_thres,"Show")
    setproperty!(button_thres,:active,false)
    push!(vbox1_3_1,button_thres)

    #SPIKE
    frame_hold=@Frame("Spike")
    vbox1_2[1,4]=frame_hold
    vbox_hold=@Grid()
    push!(frame_hold,vbox_hold)

    button_hold = @CheckButton("Hold on")
    setproperty!(button_hold,:active,false)
    #vbox_hold[1,1]=button_hold

    button_pause=@ToggleButton()
    add_button_label(button_pause,"Pause")
    vbox_hold[2,2]=button_pause

    button_clear=@Button()
    add_button_label(button_clear,"Refresh")
    vbox_hold[1,2]=button_clear

    button_buffer = @CheckButton("Buffer On")
    setproperty!(button_buffer,:active,true)
    
    #CLUSTER
    frame1_4=@Frame("Clustering")
    
    vbox1_3_2=@Grid()
    push!(frame1_4,vbox1_3_2)

    button_sort1 = @Button()
    button_sort2 = @Button()
    button_sort3 = @Button()

    button_sort4 = @Button()
    button_sort5 = @Button()

    check_sort1 = @CheckButton()

    slider_sort = @Scale(false, 0, 100,1)
    adj_sort = @Adjustment(slider_sort)
    setproperty!(adj_sort,:value,50)
    slider_sort_label=@Label("Slider Label")

    sort_list=@ListStore(Int32)
    push!(sort_list,(0,))
    sort_tv=@TreeView(TreeModel(sort_list))
    sort_r1=@CellRendererText()
    sort_c1=@TreeViewColumn("Cluster",sort_r1, Dict([("text",0)]))
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
    
    myscroll=@ScrolledWindow()
    Gtk.GAccessor.min_content_height(myscroll,150)
    Gtk.GAccessor.min_content_width(myscroll,100)
    push!(myscroll,sort_tv)
    vbox1_3_2[1,10]=myscroll
    vbox1_3_2[1,11]=@Canvas(150,10)

    vbox1_2[1,5]=frame1_4 |> showall

    #COLUMN 2 - Threshold slider
    vbox_slider=@Box(:v)
    thres_slider = @Scale(true, -300,300,1)
    adj_thres = @Adjustment(thres_slider)
    setproperty!(adj_thres,:value,0)

    c_thres=@Canvas(10,200)
    setproperty!(c_thres,:vexpand,false)
    
    Gtk.GAccessor.inverted(thres_slider,true)
    Gtk.GAccessor.draw_value(thres_slider,false)

    setproperty!(thres_slider,:vexpand,true)
    push!(vbox_slider,thres_slider)
    push!(vbox_slider,c_thres)
    grid[3,2]=vbox_slider
    

    #COLUMN 3 - MAXIMIZED CHANNEL PLOTTING
    
    #ROW 2
    c_grid=@Grid()
    
    c2=@Canvas(500)
    #c2=@Canvas()
    @guarded draw(c2) do widget
        ctx = getgc(c2)
        clear_c2(c2,1)
    end
    show(c2)
    c_grid[1,1]=c2
    setproperty!(c2,:hexpand,true)
    setproperty!(c2,:vexpand,true)

    #ROW 2
    c3=@Canvas(500,200)     
    @guarded draw(c3) do widget
        ctx = getgc(c3)
        clear_c3(c3,1)
    end
    show(c3)
    c_grid[1,2]=c3
    #setproperty!(c3,:hexpand,true)

    grid[4,2]=c_grid

    #ROW 3
    c2_slider=@Scale(false, 1:16)
    adj2 = @Adjustment(c2_slider)
    setproperty!(adj2,:value,1)
    grid[4,3]=c2_slider
 
    #COLUMN 3 - 16 CHANNEL DISPLAY

    #ROW 1 - Time
    s_label=@Label("0")
    m_label=@Label("0")
    h_label=@Label("0")
    sm_label=@Label(":")
    mh_label=@Label(":")

    frame_time=@Frame("Time Elapsed")
    grid[5,1]=frame_time
    hbox_time=@ButtonBox(:h)
push!(frame_time,hbox_time)

    push!(hbox_time,h_label)
    push!(hbox_time,mh_label)
push!(hbox_time,m_label)
    push!(hbox_time,sm_label)
    push!(hbox_time,s_label)
    
    
    #ROW 2
#c=@Canvas(500,800)
c=@Canvas(500)
    @guarded draw(c) do widget
        ctx = getgc(c)
        set_source_rgb(ctx,0.0,0.0,0.0)
        set_operator(ctx,Cairo.OPERATOR_SOURCE)
        paint(ctx)
    end
    show(c)   
    grid[5,2]=c
    setproperty!(c,:vexpand,true)

    #ROW 3
    #Which 16 channels can be selected with a slider
    c_slider = @Scale(false, 0:(div(length(r.nums)-1,16)+1))
    adj = @Adjustment(c_slider)
    setproperty!(adj,:value,1)
    grid[5,3]=c_slider

    #COLUMN 4
    #ROW 2
    vbox_42=@Box(:v)
    grid[6,2]=vbox_42
    
    vbox_rb_upper=@Box(:v)
    push!(vbox_42,vbox_rb_upper)
    
    push!(vbox_rb_upper,@Label("Top Panel"))
    
    rbs=Array(RadioButton,5)
    rbs[1]=@RadioButton("16 Channel",active=true)
    rbs[2]=@RadioButton(rbs[1],"32 Channel")
    rbs[3]=@RadioButton(rbs[2],"64 Channel")
    rbs[4]=@RadioButton(rbs[3],"64 Raster")
    rbs[5]=@RadioButton(rbs[4],"Blank")
    
    push!(vbox_rb_upper,rbs[1])
    push!(vbox_rb_upper,rbs[2])
    push!(vbox_rb_upper,rbs[3])
    push!(vbox_rb_upper,rbs[4])
    push!(vbox_rb_upper,rbs[5])
    
c_rb=@Canvas(40)
setproperty!(c_rb,:vexpand,true)
    
    push!(vbox_42,c_rb)
    
    vbox_rb_lower=@Box(:v)
    push!(vbox_42,vbox_rb_lower)
    push!(vbox_rb_lower,@Label("Lower Panel"))
    
    rbs2=Array(RadioButton,7)
    rbs2[1]=@RadioButton("Events",active=true)
    rbs2[2]=@RadioButton(rbs2[1],"16 Raster")
    rbs2[3]=@RadioButton(rbs2[2],"32 Raster")
    rbs2[4]=@RadioButton(rbs2[3],"Soft Scope")
    rbs2[5]=@RadioButton(rbs2[4],"64 Channel")
rbs2[6]=@RadioButton(rbs2[5],"64 Raster")
rbs2[7]=@RadioButton(rbs2[6],"Nothing")

    push!(vbox_rb_lower,rbs2[1])
    push!(vbox_rb_lower,rbs2[2])
    push!(vbox_rb_lower,rbs2[3])
    push!(vbox_rb_lower,rbs2[4])
    push!(vbox_rb_lower,rbs2[5])
    push!(vbox_rb_lower,rbs2[6])
    push!(vbox_rb_lower,rbs2[7])
		
    #MENU ITEMS
    
    #SAVING
    saveopts = @MenuItem("_Save")
    savemenu = @Menu(saveopts)
    save_ts_ = @MenuItem("Save Time Stamps")
    push!(savemenu,save_ts_)
    save_v_ = @MenuItem("Save Voltage")
    push!(savemenu,save_v_)
    
    #SORTING
    sortopts = @MenuItem("_Sorting")
    sortmenu = @Menu(sortopts)
    load_sort_ = @MenuItem("Load Sorting Parameters")
    push!(sortmenu,load_sort_)
    save_sort_ = @MenuItem("Save Sorting Parameters")
    push!(sortmenu,save_sort_)
	
    #Reference Electrode
    refopts = @MenuItem("_Reference Electrodes")
    refmenu = @Menu(refopts)
    define_ref_ = @MenuItem("Define Reference Configuration")
    push!(refmenu,define_ref_)
	
    #Export
exopts = @MenuItem("_Export")
    exmenu = @Menu(exopts)
    export_plex_ = @MenuItem("Plexon")
    push!(exmenu,export_plex_)
    export_klusta_ = @MenuItem("KlustaFormat")
    push!(exmenu,export_klusta_)
    export_nwb_ = @MenuItem("NWB")
    push!(exmenu,export_nwb_)
    export_jld_ = @MenuItem("JLD")
    push!(exmenu,export_jld_)
export_mat_ = @MenuItem("MAT")
push!(exmenu,export_mat_)

    #Options
    opopts = @MenuItem("_Options")
opmenu = @Menu(opopts)

op_align = @MenuItem("Alignment")
push!(opmenu,op_align)
op_align_menu = @Menu(op_align)
op_align_min = @MenuItem("Minimum")
push!(op_align_menu,op_align_min)
op_align_cross = @MenuItem("Threshold Crossing")
push!(op_align_menu,op_align_cross)


#Autosort
    svopts = @MenuItem("_Sorting")
svmenu = @Menu(svopts)

sv_open = @MenuItem("Sort Viewer")
push!(svmenu,sv_open)
    
    mb = @MenuBar()
    push!(mb,saveopts)
    push!(mb,sortopts)
push!(mb,refopts)
push!(mb,exopts)
push!(mb,opopts)
push!(mb,svopts)
grid[4,1]=mb

# Reference popup
ref_grid=@Grid()

ref_list1=@ListStore(Int32)
for i=1:size(r.v,2)
    push!(ref_list1,(i,))
end
ref_tv1=@TreeView(TreeModel(ref_list1))
ref_r1=@CellRendererText()
ref_c1=@TreeViewColumn("New Reference:",ref_r1, Dict([("text",0)]))

ref_tv1_s=Gtk.GAccessor.selection(ref_tv1)
    
push!(ref_tv1,ref_c1)
    
ref_scroll1=@ScrolledWindow()
Gtk.GAccessor.min_content_height(ref_scroll1,350)
Gtk.GAccessor.min_content_width(ref_scroll1,175)
push!(ref_scroll1,ref_tv1)

ref_list2=@ListStore(Int32)
for i=1:size(r.v,2)
    push!(ref_list2,(i,))
end
ref_tv2=@TreeView(TreeModel(ref_list2))
ref_r2=@CellRendererText()
ref_c2=@TreeViewColumn("Apply Reference To:",ref_r2, Dict([("text",0)]))

ref_tv2_s=Gtk.GAccessor.selection(ref_tv2)
Gtk.GAccessor.mode(ref_tv2_s,Gtk.GConstants.GtkSelectionMode.MULTIPLE)
    
push!(ref_tv2,ref_c2)
    
ref_scroll2=@ScrolledWindow()
Gtk.GAccessor.min_content_height(ref_scroll2,350)
Gtk.GAccessor.min_content_width(ref_scroll2,175)
push!(ref_scroll2,ref_tv2)

ref_button2=@Button("Select All/None")
ref_button3=@Button("Apply")

ref_grid[1,1]=ref_scroll1
ref_grid[2,1]=@Canvas(50,350)
ref_grid[3,1]=ref_scroll2
ref_grid[3,2]=ref_button2
ref_grid[2,3]=@Canvas(50,50)
ref_grid[3,4]=ref_button3
ref_win=@Window(ref_grid)
setproperty!(ref_win, :title, "Reference Channel Select")

showall(ref_win)
visible(ref_win,false)

#SortView

sortview_handles = SpikeSorting.sort_gui()
visible(sortview_handles.win,false)

#POPUP MENUS

#Enable-Disable
    popupmenu = @Menu()
    popup_enable = @MenuItem("Enable")
    push!(popupmenu, popup_enable)
    popup_disable = @MenuItem("Disable")
    push!(popupmenu, popup_disable)
showall(popupmenu)

#Event
popup_event = @Menu()
event_handles=Array(Gtk.GtkMenuItemLeaf,0)
for i=1:8
    push!(event_handles,@MenuItem(string("Analog ",i)))
    push!(popup_event,event_handles[i])
end

for i=1:16
    push!(event_handles,@MenuItem(string("TTL ",i)))
    push!(popup_event,event_handles[8+i])
end

popup_event_none=@MenuItem("None")
push!(popup_event,popup_event_none)
showall(popup_event)
    
    setproperty!(grid, :column_spacing, 15) 
    setproperty!(grid, :row_spacing, 15) 
    win = @Window(grid, "Intan.jl GUI") |> showall

#Soft Scope

popupmenu_scope = @Menu()
popupmenu_voltage=@MenuItem("Voltage Scale")
popupmenu_time=@MenuItem("Time Scale")
popupmenu_thres=@MenuItem("Threshold")
push!(popupmenu_scope,popupmenu_voltage)
push!(popupmenu_scope,popupmenu_time)
push!(popupmenu_scope,popupmenu_thres)


popupmenu_voltage_select=@Menu(popupmenu_voltage)
scope_v_handles=Array(Gtk.GtkMenuItemLeaf,0)
voltage_scales=[1, 50, 100, 200, 500]
for i=1:5
    push!(scope_v_handles,@MenuItem(string(voltage_scales[i]))) 
    push!(popupmenu_voltage_select,scope_v_handles[i])
end

popupmenu_time_select=@Menu(popupmenu_time)
scope_t_handles=Array(Gtk.GtkMenuItemLeaf,0)
time_scales=[1, 2, 3, 4, 5]
for i=1:5
    push!(scope_t_handles,@MenuItem(string(time_scales[i]))) 
    push!(popupmenu_time_select,scope_t_handles[i])
end

popupmenu_thres_select=@Menu(popupmenu_thres)
scope_thres_handles=Array(Gtk.GtkMenuItemLeaf,0)
push!(scope_thres_handles,@MenuItem("On"))
push!(popupmenu_thres_select,scope_thres_handles[1])
push!(scope_thres_handles,@MenuItem("Off"))
push!(popupmenu_thres_select,scope_thres_handles[2])

showall(popupmenu_scope)   


#Prepare saving headers

mkdir(r.save.folder)

if typeof(r.save)==SaveAll
    prepare_v_header(r)
    prepare_stamp_header(r)
elseif typeof(r.save)==SaveNone
    prepare_stamp_header(r)
end

    #Callback functions that interact with canvas depend on spike sorting method that is being used

    scales=ones(Float64,size(r.v,2),2)
    scales[:,2]=scales[:,2].*.2
offs=zeros(Int64,size(r.v,2))

scope_mat=ones(Float64,500,3)

for i=1:500
    scope_mat[i,1]=550.0
    scope_mat[i,2]=650.0
    scope_mat[i,3]=750.0
end

sort_widgets=Sort_Widgets(button_sort1,button_sort2,button_sort3,button_sort4,check_sort1)
thres_widgets=Thres_Widgets(thres_slider,adj_thres,button_thres_all,button_thres)
gain_widgets=Gain_Widgets(sb2,sb,gain_checkbox,button_gain)
spike_widgets=Spike_Widgets(button_hold,button_buffer,button_clear,button_pause)

    #Create type with handles to everything
handles=Gui_Handles(win,button_run,button_init,button_cal,c_slider,adj,c2_slider,adj2,c,c2,c3,1,1,1,
scales,offs,(0.0,0.0),(0.0,0.0),0,zeros(Int64,length(r.nums)),zeros(Int64,length(r.nums),2),sb,
button_gain,sb2,0,button_thres_all,-1.*ones(Int64,6),trues(length(r.nums)),false,
mytime(0,h_label,0,m_label,0,s_label),r.s[1].s.win,1,1,popupmenu,popup_event,rbs,rbs2,scope_mat,sb_offset,
adj_thres,thres_slider,false,zeros(Int16,r.s[1].s.win+1,500),1,1,button_buffer,button_hold,false,
zeros(Int64,500),Array(SpikeSorting.mywin,0),slider_sort,adj_sort,sort_list,sort_tv,button_pause,1,1,
zeros(Int64,500),zeros(UInt32,20),zeros(UInt32,500),zeros(Int64,50),ref_win,ref_tv1,ref_tv2,ref_list1,ref_list2,
gain_checkbox,false,SoftScope(r.sr),popupmenu_scope,sort_widgets,thres_widgets,gain_widgets,spike_widgets,sortview_handles)

    #Connect Callbacks to objects on GUI
if typeof(r.s[1].c)==ClusterWindow
    id = signal_connect(canvas_press_win,c2,"button-press-event",Void,(Ptr{Gtk.GdkEventButton},),false,(handles,r))
    id = signal_connect(canvas_release_win,c2,"button-release-event",Void,(Ptr{Gtk.GdkEventButton},),false,(handles,r))
    id = signal_connect(b1_cb_win,button_sort1,"clicked",Void,(),false,(handles,r))
    setproperty!(button_sort1,:label,"Delete Cluster")
    id = signal_connect(b2_cb_win,button_sort2,"clicked",Void,(),false,(handles,r))
    setproperty!(button_sort2,:label,"Delete Window")
    id = signal_connect(b3_cb_win,button_sort3,"clicked",Void,(),false,(handles,r))
    setproperty!(button_sort3,:label,"Show Windows")
    id = signal_connect(b4_cb_win,button_sort4,"clicked",Void,(),false,(handles,r))
    setproperty!(button_sort3,:label,"Select Cluster")
    id = signal_connect(b5_cb_win,button_sort5,"clicked",Void,(),false,(handles,r))
    setproperty!(button_sort3,:label,"Select Window")

    #setproperty!(tb1,:label,"Cluster: ")
    #setproperty!(tb2,:label,"Window: ")
    
elseif typeof(r.s[1].c)==ClusterTemplate
    id = signal_connect(canvas_press_win,c2,"button-press-event",Void,(Ptr{Gtk.GdkEventButton},),false,(handles,r))
    id = signal_connect(canvas_release_template,c2,"button-release-event",Void,(Ptr{Gtk.GdkEventButton},),false,(handles,r))
    
    id = signal_connect(b1_cb_template,button_sort1,"clicked",Void,(),false,(handles,r))
    add_button_label(button_sort1,"Delete Unit")
    
    id = signal_connect(b2_cb_template,button_sort2,"clicked",Void,(),false,(handles,r))
    add_button_label(button_sort2,"Add Unit")
    
    id = signal_connect(b3_cb_template,button_sort3,"clicked",Void,(),false,(handles,r))
    add_button_label(button_sort3,"Collect Templates")
    
    id = signal_connect(b4_cb_template,button_sort4,"clicked",Void,(),false,(handles,r))
    add_button_label(button_sort4,"Show Template Bounds")
    
    setproperty!(check_sort1,:label,"Show Template")
    id = signal_connect(check_cb_template,check_sort1,"clicked",Void,(),false,(handles,r))

    setproperty!(slider_sort_label,:label,"Tolerance")

    id = signal_connect(template_slider, slider_sort, "value-changed", Void, (), false, (handles,r))
end

id = signal_connect(win_resize_cb, win, "size-allocate",Void,(Ptr{Gtk.GdkRectangle},),false,(handles,r))

    id = signal_connect(unit_select_cb,sort_tv, "row-activated", Void, (Ptr{Gtk.GtkTreePath},Ptr{Gtk.GtkTreeViewColumn}), false, (handles,r))

    id = signal_connect(thres_show_cb,button_thres,"clicked",Void,(),false,(handles,r))
id = signal_connect(c_popup_select,c,"button-press-event",Void,(Ptr{Gtk.GdkEventButton},),false,(handles,r))
id = signal_connect(c3_press_win,c3,"button-press-event",Void,(Ptr{Gtk.GdkEventButton},),false,(handles,r))
    id = signal_connect(run_cb, button_run, "clicked",Void,(),false,(handles,r))
    #id = signal_connect(auto_cb,button_auto,"clicked",Void,(),false,(handles,r))
    id = signal_connect(update_c1, c_slider, "value-changed", Void, (), false, (handles,r))
    id = signal_connect(update_c2_cb, c2_slider, "value-changed", Void, (), false, (handles,r))
    id = signal_connect(init_cb, button_init, "clicked", Void, (), false, (handles,r))
    id = signal_connect(cal_cb, button_cal, "clicked", Void, (), false, (handles,r))
    #id = signal_connect(sb_cb,sb,"value-changed", Void, (), false, (handles,r))
id = signal_connect(sb2_cb,sb2, "value-changed",Void,(),false,(handles,r))
id = signal_connect(popup_enable_cb,popup_enable,"activate",Void,(),false,(handles,r))
id = signal_connect(popup_disable_cb,popup_disable,"activate",Void,(),false,(handles,r))
id = signal_connect(export_plex_cb, export_plex_, "activate",Void,(),false,(handles,r))
id = signal_connect(export_jld_cb, export_jld_, "activate",Void,(),false,(handles,r))
id = signal_connect(export_mat_cb, export_mat_, "activate",Void,(),false,(handles,r))
id = signal_connect(save_config_cb, save_sort_, "activate",Void,(),false,(handles,r))
id = signal_connect(load_config_cb, load_sort_, "activate",Void,(),false,(handles,r))
id = signal_connect(sb_off_cb, sb_offset, "value-changed",Void,(),false,(handles,r))
id = signal_connect(thres_cb,thres_slider,"value-changed",Void,(),false,(handles,r))
id = signal_connect(buf_on_cb,button_buffer,"clicked",Void,(),false,(handles,r))
id = signal_connect(hold_cb,button_hold,"clicked",Void,(),false,(handles,r))
id = signal_connect(pause_cb,button_pause,"toggled",Void,(),false,(handles,r))
id = signal_connect(clear_button_cb,button_clear,"clicked",Void,(),false,(handles,r))

for i=1:8
    id = signal_connect(popup_event_cb,event_handles[i],"activate",Void,(),false,(handles,r,i-1))
end

for i=9:24
    id = signal_connect(popup_event_cb,event_handles[i],"activate",Void,(),false,(handles,r,i-1))
end

id = signal_connect(popup_event_cb,popup_event_none,"activate",Void,(),false,(handles,r,-1))

for i=1:5
    id = signal_connect(rb1_cb,rbs[i],"clicked",Void,(),false,(handles,r,i))
end

for i=1:7
    id = signal_connect(rb2_cb,rbs2[i],"clicked",Void,(),false,(handles,r,i))
end

id = signal_connect(ref_cb, define_ref_, "activate",Void,(),false,(handles,r))

for i=1:5
    signal_connect(scope_popup_v_cb,scope_v_handles[i],"activate",Void,(),false,(handles,r,i-1))
end

for i=1:5
    signal_connect(scope_popup_t_cb,scope_t_handles[i],"activate",Void,(),false,(handles,r,i-1))
end

for i=1:2
    signal_connect(scope_popup_thres_cb,scope_thres_handles[i],"activate",Void,(),false,(handles,r,i-1))
end

#Reference

#id = signal_connect(ref_b1_cb, ref_button1, "clicked",Void,(),false,(handles,r))
id = signal_connect(ref_b2_cb, ref_button2, "clicked",Void,(),false,(handles,r))
id = signal_connect(ref_b3_cb, ref_button3, "clicked",Void,(),false,(handles,r))

id = signal_connect(gain_check_cb,gain_checkbox, "clicked", Void,(),false,(handles,r))

signal_connect(ref_win, :delete_event) do widget, event
    visible(ref_win, false)
    true
end

#SortView

id = signal_connect(sv_open_cb, sv_open, "activate",Void,(),false,(handles,r))

signal_connect(sortview_handles.win, :delete_event) do widget, event
    visible(sortview_handles.win, false)
    true
end

handles  
end

#Drawing
function run_cb(widgetptr::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    widget = convert(ToggleButton, widgetptr)
	          
    @async if getproperty(widget,:active,Bool)==true
        
        #unpack tuple
        han, rhd = user_data
              
	if rhd.debug.state==false
            map(runBoard,rhd.fpga)
        end
        while getproperty(widget,:active,Bool)==true
           main_loop(rhd,han) 
        end       
    end
        
    nothing
end

function main_loop(rhd::RHD2000,han::Gui_Handles)
    #get spikes and sort
    if rhd.debug.state==false
        if typeof(rhd.fpga)==DArray{Intan.FPGA,1,Array{Intan.FPGA,1}} #parallel

            if rhd.cal<3
                calibrate_parallel(rhd.fpga,rhd.s,rhd.v,rhd.buf,rhd.nums,rhd.time,rhd.cal)
            else
                onlinesort_parallel(rhd.fpga,rhd.s,rhd.v,rhd.buf,rhd.nums,rhd.time)
            end
            cal_update(rhd)
	    myread=true
        else
            myread=readDataBlocks(rhd,1)
        end
    else
        myread=readDataBlocks(rhd)
    end
    #=
    if myread
        rhd.ttl_state = !rhd.ttl_state
        sendTimePulse(rhd.fpga[1],rhd.ttl_state)
    end
    =#
    #process and output (e.g. kalman, spike triggered stim calc, etc)
    do_task(rhd.task,rhd,myread)
    
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
	        plot_events(rhd,han,han.draws)
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
            else 
            end

            update_time(rhd,han)         
	    reveal(han.c)
                
	    if (han.num>0)&(!han.pause)                     
		draw_spike(rhd,han)
	    end
            draw_c3(rhd,han)
	end
	reveal(han.c2)
        reveal(han.c3)
	han.draws+=1
	if han.draws>500
	    han.draws=0
            if han.num16>0
	        clear_c(han)
            end
            if (!han.hold)&(!han.pause)
	        clear_c2(han.c2,han.spike)
            end
            clear_c3(han.c3,han.spike)
            #Display threshold if box checked
            if han.show_thres==true
                plot_thres(han,rhd,rhd.s[1].d)
            end
            #Sort Button
            if han.sort_cb
                draw_templates(rhd.s[han.spike].c,han)
            end
	end
	#write to disk, clear buffers
        queueToFile(rhd,rhd.save)
    end
    sleep(.00001)
    #sleep(.02) #debug
    nothing
end

function update_c1(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})
    
    han, rhd = user_data 
    han.num16=getproperty(han.adj,:value,Int64) # 16 channels
    chan_per_display = getproperty(han.adj2,:upper,Int64)

    if han.num16>0
        
        han.spike=chan_per_display*han.num16-chan_per_display+han.num      

        clear_c(han)
        clear_c2(han.c2,han.spike)

        #Audio output
        set_audio(rhd,han)
        
        #Display Gain
        setproperty!(han.gainbox,:value,round(Int,han.scale[han.spike,1]*-1000))

        #Display Threshold
        mythres=(rhd.s[han.spike].thres-han.offset[han.spike])*han.scale[han.spike,1]*-1
        setproperty!(han.adj_thres,:value,round(Int64,mythres)) #show threshold

        #Spike Buffer
        if getproperty(han.buf_button,:active,Bool)
            han.buf_ind=1
            han.buf_count=1
        end

	#Update treeview
        update_treeview(rhd,han)
    end
    nothing    
end

function update_c2_cb(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data
    update_c2(han,rhd)
    nothing
end

function add_button_label(button,mylabel)
    b_label=@Label(mylabel)
    Gtk.GAccessor.markup(b_label, string("""<span size="x-small">""",mylabel,"</span>"))
    push!(button,b_label)
    show(b_label)
end

function change_button_label(button,mylabel)
    hi=Gtk.GAccessor.child(button)
    Gtk.GAccessor.markup(hi, string("""<span size="x-small">""",mylabel,"</span>"))
end


function update_c2(han::Gui_Handles,rhd::RHD2000)

    han.num=getproperty(han.adj2, :value, Int64) # primary display
    chan_per_display = getproperty(han.adj2,:upper,Int64)

    if han.num16>0

        old_spike=rem(han.spike-1,chan_per_display)+1
        han.spike=chan_per_display*han.num16-chan_per_display+han.num

        clear_c2(han.c2,han.spike)

        #Audio output
        set_audio(rhd,han)

        #Display Gain
        setproperty!(han.gainbox,:value,round(Int,han.scale[han.spike,1]*-1000))

        #Display Threshold
        mythres=(rhd.s[han.spike].thres-han.offset[han.spike])*han.scale[han.spike,1]*-1
        setproperty!(han.adj_thres,:value,round(Int64,mythres)) #show threshold

        #Spike Buffer
        if getproperty(han.buf_button,:active,Bool)
            han.buf_ind=1
            han.buf_count=1
        end

        #Highlight channel
        highlight_channel(han,old_spike)

        #Update treeview
        update_treeview(rhd,han)

        #Sort Button
        if han.sort_cb
            draw_templates(rhd.s[han.spike].c,han)
        end

        if han.show_thres==true
            plot_thres(han,rhd,rhd.s[1].d)
        end
    end
        
    nothing
end

function update_treeview(rhd::RHD2000,han::Gui_Handles)

    for i=length(han.sort_list):-1:2
        deleteat!(han.sort_list,i)
    end

    for i=1:han.total_clus[han.spike]
        push!(han.sort_list,(i,))
    end

    selmodel=Gtk.GAccessor.selection(han.sort_tv)
    select!(selmodel, Gtk.iter_from_index(han.sort_list,1))
    
    nothing
end

function clear_button_cb(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han,rhd = user_data
    clear_c2(han.c2,han.spike)
    if han.show_thres==true
        plot_thres(han,rhd,rhd.s[1].d)
    end
    #Sort Button
    if han.sort_cb
        draw_templates(rhd.s[han.spike].c,han)
    end
    
    nothing
end

function highlight_channel(han::Gui_Handles,old_spike)

    ctx = getgc(han.c)
    
    if han.c_right_top==1

        (x1_i,x2_i,y1_i,y2_i)=get_multi_dims(han,4,4,16,old_spike)
        (x1_f,x2_f,y1_f,y2_f)=get_multi_dims(han,4,4,16,han.num)
        
    elseif han.c_right_top==2

        (x1_i,x2_i,y1_i,y2_i)=get_multi_dims(han,6,6,32,old_spike)
        (x1_f,x2_f,y1_f,y2_f)=get_multi_dims(han,6,6,32,han.num)
        
    elseif han.c_right_top==3
        (x1_i,x2_i,y1_i,y2_i)=get_multi_dims(han,6,11,64,old_spike)
        (x1_f,x2_f,y1_f,y2_f)=get_multi_dims(han,6,11,64,han.num)
    end

    draw_box(x1_i,y1_i,x2_i,y2_i,(0.0,0.0,0.0),2.0,ctx)
    draw_box(x1_i,y1_i,x2_i,y2_i,(1.0,1.0,1.0),1.0,ctx)
    draw_box(x1_f,y1_f,x2_f,y2_f,(1.0,0.0,1.0),1.0,ctx)

    nothing
end

function draw_box(x1,y1,x2,y2,mycolor,linewidth,ctx)
    move_to(ctx,x1,y1)
    line_to(ctx,x2,y1)
    line_to(ctx,x2,y2)
    line_to(ctx,x1,y2)
    line_to(ctx,x1,y1)
    set_source_rgb(ctx,mycolor[1],mycolor[2],mycolor[3])
    set_line_width(ctx,linewidth)
    stroke(ctx)
    nothing
end

function set_audio(rhd::RHD2000,han::Gui_Handles)

    selectDacDataStream(rhd.fpga[1],0,div(han.spike-1,32))
    selectDacDataChannel(rhd.fpga[1],0,rem(han.spike-1,32))

    if rhd.refs[han.spike]>0
        enableDac(rhd.fpga[1],1,true)
        selectDacDataStream(rhd.fpga[1],1,div(rhd.refs[han.spike]-1,32))
        selectDacDataChannel(rhd.fpga[1],1,rem(rhd.refs[han.spike]-1,32))
    else
        enableDac(rhd.fpga[1],1,false)
    end
    nothing
end

function init_cb(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data       
    init_board!(rhd)
    init_task(rhd.task,rhd)

    nothing
end

function cal_cb(widget::Ptr, user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data

    mycal=getproperty(han.cal,:active,Bool)
        
    if mycal==true
        rhd.cal=0
    else
        rhd.cal=3
    
        @inbounds for i=1:length(rhd.s)
            han.offset[i]=0.0
            han.scale[i,1] = -.125
            han.scale[i,2] = -.125*.25
        end

        mythres=(rhd.s[han.spike].thres-han.offset[han.spike])*han.scale[han.spike,1]*-1
        
        setproperty!(han.gainbox,:value,round(Int,han.scale[han.spike,1]*-1000)) #show gain
        setproperty!(han.adj_thres,:value,round(Int64,mythres)) #show threshold
    end

    nothing
end

function buf_on_cb(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})
    han, rhd = user_data

    mybuf=getproperty(han.buf_button,:active,Bool)

    if mybuf==true
        han.buf_count=1
        han.buf_ind=1
        for i=1:length(han.buf_clus)
            han.buf_clus[i]=0
        end
    else
        han.buf_count=0
    end

    nothing
end

function hold_cb(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})
    han, rhd = user_data

    han.hold=getproperty(han.hold_button,:active,Bool)

    nothing
end

function pause_cb(widgetptr::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data
    
    widget = convert(ToggleButton, widgetptr)

    if getproperty(widget,:active,Bool)
        han.pause=true
        change_button_label(widget,"Resume")
    else
        han.pause=false
        change_button_label(widget,"Pause")
        han.hold=getproperty(han.hold_button,:active,Bool)
    end

    nothing
end

function win_resize_cb(widget::Ptr,param_tuple,user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data

    ctx=getgc(han.c2)
    myheight=height(ctx)
    
    setproperty!(han.adj_thres,:upper,myheight/2)
    setproperty!(han.adj_thres,:lower,-myheight/2)
    
    nothing
end

function update_time(rhd::RHD2000,han::Gui_Handles)

    total_seconds=convert(Int64,div(rhd.time[1,1],rhd.sr))

    this_h=div(total_seconds,3600)

    total_seconds=total_seconds - this_h*3600 

    this_m=div(total_seconds,60)

    this_s=total_seconds - this_m*60

    if this_s != han.time.s
        setproperty!(han.time.s_l,:label,string(this_s))
        han.time.s=this_s
    end
    if this_m != han.time.m
        setproperty!(han.time.m_l,:label,string(this_m))
        han.time.m=this_m
    end
    if this_h != han.time.h
        setproperty!(han.time.h_l,:label,string(this_h))
        han.time.h=this_h
    end

    nothing
end

function thres_show_cb(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data

    mywidget = convert(CheckButton, widget)

    han.show_thres=getproperty(mywidget,:active,Bool)
	          
    if han.show_thres==true
        plot_thres(han,rhd,rhd.s[1].d)
    end

    nothing
end

function plot_thres(han::Gui_Handles,rhd::RHD2000,d::DetectAbs)

    ctx = getgc(han.c2)
    mywidth=width(ctx)

    thres=getproperty(han.adj_thres,:value,Int)
    move_to(ctx,1,300-thres)
    line_to(ctx,mywidth,300-thres)

    move_to(ctx,1,300+thres)
    line_to(ctx,mywidth,300+thres)

    set_source_rgb(ctx,1.0,1.0,1.0)
    stroke(ctx)
    
    nothing
end

function plot_thres(han::Gui_Handles,rhd::RHD2000,d::DetectNeg)

    ctx = getgc(han.c2)
    mywidth=width(ctx)
    myheight=height(ctx)

    thres=getproperty(han.adj_thres,:value,Int)

    move_to(ctx,1,myheight/2-thres+2)
    line_to(ctx,mywidth,myheight/2-thres+2)

    move_to(ctx,1,myheight/2-thres-2)
    line_to(ctx,mywidth,myheight/2-thres-2)

    set_line_width(ctx,5.0)
    set_source_rgb(ctx,0.0,0.0,0.0)
    stroke(ctx)

    move_to(ctx,1,myheight/2-thres)
    line_to(ctx,mywidth,myheight/2-thres)
    set_line_width(ctx,1.0)
    set_source_rgb(ctx,1.0,1.0,1.0)
    stroke(ctx)
    
    nothing
end

#Threshold
function thres_cb(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data

    mythres=getproperty(han.adj_thres,:value,Int)
    
    if getproperty(han.thres_all,:active,Bool)      
        @inbounds for i=1:length(rhd.s)
            rhd.s[i].thres=-1*mythres/han.scale[i,1]+han.offset[i]
        end    
    else
        @inbounds rhd.s[han.spike].thres=-1*mythres/han.scale[han.spike,1]+han.offset[han.spike]
    end

    setproperty!(han.sb,:value,mythres)

    if han.show_thres==true
        plot_thres(han,rhd,rhd.s[1].d)
    end

    nothing
end

#Gain
function sb2_cb(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data

    mygain=getproperty(han.gain,:active,Bool)

    gainval=getproperty(han.gainbox,:value,Int)
    mythres=getproperty(han.adj_thres,:value,Int)

    if mygain==true
        han.scale[:,1]=-1.*gainval/1000
        han.scale[:,2]=-.2*gainval/1000
        for i=1:length(han.offset)
            rhd.s[i].thres=-1*mythres/han.scale[i,1]+han.offset[i]
        end
    else
        han.scale[han.spike,1]=-1*gainval/1000
        han.scale[han.spike,2]=-.2*gainval/1000
        rhd.s[han.spike].thres=-1*mythres/han.scale[han.spike,1]+han.offset[han.spike]
    end

    nothing
end

function gain_check_cb(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data

    mygain=getproperty(han.gain_multiply,:active,Bool)

    if mygain
        Gtk.GAccessor.increments(han.gainbox,10,10)
    else
        Gtk.GAccessor.increments(han.gainbox,1,1)
    end

    nothing
end

#Offset
function sb_off_cb(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data

    mygain=getproperty(han.gain,:active,Bool)

    offval=getproperty(han.offbox,:value,Int)
    mythres=getproperty(han.adj_thres,:value,Int)

    if mygain==true
        for i=1:length(han.offset)
            han.offset[i]=offval
            rhd.s[i].thres=-1*mythres/han.scale[i,1]+han.offset[i]
        end
    else
        han.offset[han.spike]=offval
        rhd.s[han.spike].thres=-1*mythres/han.scale[han.spike,1]+han.offset[han.spike]
    end

    nothing
end

#=
SortView Callbacks
=#

function sv_open_cb(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data
    han.sortview_widgets.spike_buf=han.spike_buf
    han.sortview_widgets.buf_clus=han.buf_clus
    han.sortview_widgets.buf_count=han.buf_count
    visible(han.sortview_widgets.win,true)
    nothing
end

#=
Export Callbacks
=#
function export_plex_cb(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data

    write_plex(save_dialog("Export to Plex",han.win),rhd.save.v,rhd.save.ts)

    nothing
end

function export_jld_cb(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han,rhd = user_data

    #get prefix for exported data name

    #find out what to export

    #call appropriate save functions based on above
    
    nothing
end

function export_mat_cb(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han,rhd = user_data

    nothing
end

function save_config_cb(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data

    filepath=save_dialog("Save configuration",han.win)

    if filepath[end-3:end]==".jld"
    else
        filepath=string(filepath,".jld")
    end
    
    file = jldopen(filepath, "w")
    
    write(file, "Gain", han.scale)
    write(file, "Offset", han.offset)
    write(file, "Sorting", rhd.s)
    write(file, "total_clus",han.total_clus)
    write(file, "Enabled", han.enabled)
    write(file, "Reference",rhd.refs)

    close(file)

    nothing
end

function ref_cb(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data

    visible(han.ref_win,true)
    nothing
end

function load_config_cb(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data

    filepath=open_dialog("Load Configuration",han.win)

    c = jldopen(filepath, "r") do file
        g=read(file,"Gain")

        for i=1:length(g)
            han.scale[i]=g[i]
        end

        o=read(file,"Offset")

        for i=1:length(o)
            han.offset[i]=o[i]
        end

        s=read(file,"Sorting")

        for i=1:length(s)
            rhd.s[i]=s[i]
        end

        total_clus=read(file,"total_clus")
        for i=1:length(total_clus)
            han.total_clus[i]=total_clus[i]
        end

        e=read(file,"Enabled")

        for i=1:length(e)
            han.enabled[i]=e[i]
        end

        refs=read(file,"Reference")

        for i=1:length(refs)
            rhd.refs[i]=refs[i]
        end
    end

    update_treeview(rhd,han)

    update_ref(rhd,han)

    nothing
end

function update_ref(rhd::RHD2000,han::Gui_Handles)

    selmodel_l=Gtk.GAccessor.selection(han.ref_tv1)
    selmodel_r=Gtk.GAccessor.selection(han.ref_tv2)
    
    for i=1:size(rhd.v,2)

        myref=rhd.refs[i]

        if myref!=0

            select!(selmodel_l,Gtk.iter_from_index(han.ref_list1,myref))
            select!(selmodel_r,Gtk.iter_from_index(han.ref_list2,i))         
        end
    end
    nothing
end

#=
Rubber Band functions adopted from GtkUtilities.jl package by Tim Holy 2015
=#

immutable Vec2
    x::Float64
    y::Float64
end

type RubberBand
    pos1::Vec2
    pos2::Vec2
    moved::Bool
    minpixels::Int
end

function rb_erase(r::Cairo.CairoContext, ctxcopy)
    # Erase the previous rubberband by copying from back surface to front
    set_source(r, ctxcopy)
    set_line_width(r, 3)
    stroke(r)
end

function rb_draw(r::Cairo.CairoContext, rb::RubberBand)
    rb_set(r, rb)
    set_line_width(r, 1)
    #set_source_rgb(r, 0, 0, 0)
    #stroke_preserve(r)
    set_source_rgb(r, 1, 1, 1)
    stroke_preserve(r)
end

function rb_set(r::Cairo.CairoContext, rb::RubberBand)
    move_to(r, rb.pos1.x, rb.pos1.y)
    rel_line_to(r,rb.pos2.x-rb.pos1.x, rb.pos2.y-rb.pos1.y)
end

function rubberband_start(c::Canvas, x, y; minpixels::Int=2)
    # Copy the surface to another buffer, so we can repaint the areas obscured by the rubberband
    r = getgc(c)
    Cairo.save(r)
    ctxcopy = copy(r)
    rb = RubberBand(Vec2(x,y), Vec2(x,y), false, minpixels)
    push!((c.mouse, :button1motion),  (c, event) -> rubberband_move(c, rb, event.x, event.y, ctxcopy))
    push!((c.mouse, :motion), Gtk.default_mouse_cb)
    push!((c.mouse, :button1release), (c, event) -> rubberband_stop(c, rb, event.x, event.y, ctxcopy))
    nothing
end

function rubberband_move(c::Canvas, rb::RubberBand, x, y, ctxcopy)
    r = getgc(c)
    if rb.moved
        rb_erase(r, ctxcopy)
    end
    rb.moved = true
    
    # Draw the new rubberband
    rb.pos2 = Vec2(x, y)
    rb_draw(r, rb)
    reveal(c, false)
end

function rubberband_stop(c::Canvas, rb::RubberBand, x, y, ctxcopy)
    pop!((c.mouse, :button1motion))
    pop!((c.mouse, :motion))
    pop!((c.mouse, :button1release))
    if !rb.moved
        return
    end
    r = getgc(c)
    rb_set(r, rb)
    rb_erase(r, ctxcopy)
    restore(r)
    reveal(c, false)
    nothing
end

#=
Right Canvas Callbacks
=#

function c_popup_select(widget::Ptr,param_tuple,user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data
    event = unsafe_load(param_tuple)

    ctx=getgc(han.c)
    myheight=height(ctx)

    han.mim=(event.x,event.y)

    if event.y<(myheight-300) #top

        if han.c_right_top==1 #disable enable 16

            if event.button == 1 #left click

                (inmulti,channel_num)=check_multi(han,4,4,16,event.x,event.y)

                if inmulti
                    setproperty!(han.adj2,:value,channel_num)
                    update_c2(han,rhd)
                end
                
            elseif event.button == 3 #right click

                popup(han.popup_ed,event)
            end
        elseif han.c_right_top==2 #disable enable 32

            if event.button == 1 #left click

                (inmulti,channel_num)=check_multi(han,6,6,32,event.x,event.y)
                if inmulti
                    setproperty!(han.adj2,:value,channel_num)
                    update_c2(han,rhd)
                end
                
            elseif event.button == 3 #right click

                popup(han.popup_ed,event)
            end
            
        elseif han.c_right_top==3 #disable enable 64
            
            if event.button == 1 #left click

                (inmulti,channel_num)=check_multi(han,11,6,64,event.x,event.y)
                if inmulti
                    setproperty!(han.adj2,:value,channel_num)
                    update_c2(han,rhd)
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
                    setproperty!(han.adj2,:value,channel_num)
                    update_c2(han,rhd)
                end
                
            elseif event.button == 3 #right click

                popup(han.popup_ed,event)
            end
            
        elseif han.c_right_bottom==6 #64 channel raster - nothing
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

    ctx=getgc(han.c)

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

popup_enable_cb(w::Ptr,d::Tuple{Gui_Handles,RHD2000})=enable_disable(d[1],true)

popup_disable_cb(w::Ptr,d::Tuple{Gui_Handles,RHD2000})=enable_disable(d[1],false)

function enable_disable(han::Gui_Handles,en::Bool)

    if han.c_right_top==1 #16 channel
        (inmulti,count)=check_multi(han,4,4,16,han.mim[1],han.mim[2])
    elseif han.c_right_top==2 # 32 channel
        (inmulti,count)=check_multi(han,6,6,32,han.mim[1],han.mim[2])
    else #64 channel
        (inmulti,count)=check_multi(han,11,6,64,han.mim[1],han.mim[2])
    end

    if inmulti
        if han.c_right_top==1 #16 channel
            han.enabled[16*han.num16-16+count]=en
        elseif han.c_right_top==2 #32 channel
            han.enabled[32*han.num16-32+count]=en
        else #64 channel
            han.enabled[64*han.num16-64+count]=en
        end
    end

    nothing
end

function popup_event_cb(widgetptr::Ptr,user_data::Tuple{Gui_Handles,RHD2000,Int64})

    han, rhd, event_id = user_data

    ctx=getgc(han.c)
    myheight=height(ctx)

    chan_id=1
    if han.mim[2]<(myheight-250)
        chan_id=1
    elseif han.mim[2]<(myheight-200)
        chan_id=2
    elseif han.mim[2]<(myheight-150)
        chan_id=3
    elseif han.mim[2]<(myheight-100)
        chan_id=4
    elseif han.mim[2]<(myheight-50)
        chan_id=5
    else
        chan_id=6
    end
        
    han.events[chan_id]=event_id
    
    nothing
end

function rb1_cb(widgetptr::Ptr,user_data::Tuple{Gui_Handles,RHD2000,Int64})

    han, rhd, event_id = user_data

    if han.c_right_top != event_id
        han.c_right_top=event_id

        if event_id==3
            if han.c_right_bottom != 5
                setproperty!(han.rb2[5],:active,true)
            end
        elseif event_id==4
            if han.c_right_bottom != 6
                setproperty!(han.rb2[6],:active,true)
            end
        else
            if (han.c_right_bottom == 5)|(han.c_right_bottom == 6)
                setproperty!(han.rb2[7],:active,true)
            end
        end
    end

    if han.c_right_top == 1
	set_slider(han,16)
    elseif han.c_right_top == 2
	set_slider(han,32)
    elseif (han.c_right_top == 3)|(han.c_right_top == 4)
	set_slider(han,64)
    end
    
    clear_c(han)
    nothing
end

function set_slider(han::Gui_Handles,chan_num::Int64)
    han.num16=div(han.spike-1,chan_num)+1
    han.num=rem(han.spike-1,chan_num)+1
    setproperty!(han.adj2,:upper,chan_num)
    setproperty!(han.adj,:upper,div(length(han.enabled),chan_num))
    setproperty!(han.adj2, :value, han.num)
    setproperty!(han.adj, :value, han.num16)
    nothing
end

function rb2_cb(widgetptr::Ptr,user_data::Tuple{Gui_Handles,RHD2000,Int64})

    han, rhd, event_id = user_data

    if han.c_right_bottom != event_id
        han.c_right_bottom=event_id

        if event_id==5
            if han.c_right_top!=3
                setproperty!(han.rb1[3],:active,true)
            end
        elseif event_id==6
            if han.c_right_top != 4
                setproperty!(han.rb1[4],:active,true)
            end
        else
            if (han.c_right_top == 3)|(han.c_right_top == 4)
                setproperty!(han.rb1[1],:active,true)
            end
        end
    end

    clear_c(han)
    nothing
end

function unit_select_cb(w::Ptr,p1,p2,user_data::Tuple{Gui_Handles,RHD2000})

    han,rhd = user_data  
    select_unit(rhd,han)
end

function select_unit(rhd::RHD2000,han::Gui_Handles)
    clus=get_cluster_id(han)
    
    old_clus=han.clus

    han.clus=clus
    if clus>0
        mytol=rhd.s[han.spike].c.tol[clus]
        setproperty!(han.adj_sort, :value, mytol*50)
    end

    ctx=getgc(han.c3)

    if old_clus>0
        (x1_i,x2_i,y1_i,y2_i)=get_template_dims(han,old_clus)
        draw_box(x1_i,y1_i,x2_i,y2_i,(0.0,0.0,0.0),2.0,ctx)
        draw_box(x1_i,y1_i,x2_i,y2_i,(1.0,1.0,1.0),1.0,ctx)
    end

    if han.clus>0
        (x1_f,x2_f,y1_f,y2_f)=get_template_dims(han,han.clus)
        draw_box(x1_f,y1_f,x2_f,y2_f,(1.0,0.0,1.0),1.0,ctx)
    end
        
    nothing
end

function get_cluster_id(han::Gui_Handles)
    selmodel=Gtk.GAccessor.selection(han.sort_tv)
    iter=Gtk.selected(selmodel)

    myind=parse(Int64,Gtk.get_string_from_iter(TreeModel(han.sort_list), iter))
end

function ref_b1_cb(widget::Ptr, user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data
    selmodel=Gtk.GAccessor.selection(han.ref_tv1)
    selectall!(selmodel)

    nothing
end

function ref_b2_cb(widget::Ptr, user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data
    selmodel=Gtk.GAccessor.selection(han.ref_tv2)
    selectall!(selmodel)

    nothing
end

function ref_b3_cb(widget::Ptr, user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data

    #Left
    selmodel=Gtk.GAccessor.selection(han.ref_tv1)
    myref=parse(Int64,Gtk.get_string_from_iter(TreeModel(han.ref_list1), Gtk.selected(selmodel)))+1
    
    #Right
    for i=1:size(rhd.v,2)
        if is_selected(han.ref_list2,han.ref_tv2,i-1)
            if i==myref
                rhd.refs[i]=0
            else
                rhd.refs[i]=myref
            end
        end
    end

    nothing
end

function is_selected(store,tv,ind)
    iter=Gtk.iter_from_string_index(store,string(ind))
    selection=Gtk.GAccessor.selection(tv)
    ccall((:gtk_tree_selection_iter_is_selected, Gtk.libgtk),Bool,
    (Ptr{Gtk.GObject}, Ptr{Gtk.GtkTreeIter}),selection, Gtk.mutable(iter))
end


function canvas_press_win(widget::Ptr,param_tuple,user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data
    event = unsafe_load(param_tuple)
    
    if event.button == 1 #left click captures window
        han.mi=(event.x,event.y)
        rubberband_start(han.c2,event.x,event.y)
    elseif event.button == 3 #right click refreshes window
        clear_c2(han.c2,han.spike)
        if getproperty(han.buf_button,:active,Bool)
            han.buf_ind=1
            han.buf_count=1
        end
        if han.show_thres==true
            plot_thres(han,rhd,rhd.s[1].d)
        end
        if han.sort_cb
            draw_templates(rhd.s[han.spike].c,han)
        end
    end
    nothing
end

function coordinate_transform(han::Gui_Handles,event)

    ctx=getgc(han.c2)
    mywidth=width(ctx)
    myheight=height(ctx)

    #Convert canvas coordinates to voltage vs time coordinates
    myx=[1.0;collect(2:han.wave_points).*(mywidth/han.wave_points)]
    x1=indmin(abs(myx-han.mi[1]))
    x2=indmin(abs(myx-event.x))
    s=han.scale[han.spike,1]
    o=han.offset[han.spike]
    y1=(han.mi[2]-myheight/2+o)/s
    y2=(event.y-myheight/2+o)/s
    
    #ensure that left most point is first
    if x1>x2
        x=x1
        x1=x2
        x2=x
        y=y1
        y1=y2
        y2=y
    end
    (x1,x2,y1,y2)
end

function scope_popup_v_cb(widgetptr::Ptr,user_data::Tuple{Gui_Handles,RHD2000,Int64})

    han, rhd, event_id = user_data
    
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

function scope_popup_t_cb(widgetptr::Ptr,user_data::Tuple{Gui_Handles,RHD2000,Int64})

    han, rhd, event_id = user_data
    
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

function scope_popup_thres_cb(w::Ptr,user_data::Tuple{Gui_Handles,RHD2000,Int64})
    
    han, rhd, event_id = user_data

    if event_id==0
        han.soft.thres_on=true
    else
        han.soft.thres_on=false
    end

    nothing
end

function c3_press_win(widget::Ptr,param_tuple,user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data
    event = unsafe_load(param_tuple)
    
    if event.button == 1 #left click captures window
        check_c3_click(rhd,han,event.x,event.y)
    elseif event.button == 3 #right click refreshes window
    end
    nothing
end

function check_c3_click(rhd::RHD2000,han::Gui_Handles,x,y)

    ctx=getgc(han.c3)
    mywidth=width(ctx)
    
    total_clus = max(han.total_clus[han.spike]+1,5)

    xbounds=linspace(0.0,mywidth,total_clus+1)

    count=1
    inmulti=false
    if y<130
        for j=2:length(xbounds)
            if (x<xbounds[j])
                inmulti=true
                break
            end
            count+=1
        end
    end
    if (inmulti)&(count<han.total_clus[han.spike]+1)
        selmodel=Gtk.GAccessor.selection(han.sort_tv)
        select!(selmodel, Gtk.iter_from_index(han.sort_list,count+1))
        select_unit(rhd,han)
    end
    nothing
end

function get_template_dims(han::Gui_Handles,clus)

    ctx=getgc(han.c3)
    mywidth=width(ctx)

    total_clus = max(han.total_clus[han.spike]+1,5)
    
    xbounds=linspace(0.0,mywidth,total_clus+1)

    (xbounds[clus],xbounds[clus+1],0.0,130.0)
end
