

function makegui(r::RHD2000,s,task,fpga)

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
    
    button_cal = CheckButton("Calibrate")
    setproperty!(button_cal,:active,true)
    vbox_control[1,2]=button_cal

    #GAIN
    frame1_2=Frame("Gain")
    vbox1_2[1,2]=frame1_2
    vbox1_2_1=Grid()
    push!(frame1_2,vbox1_2_1)

    sb2=SpinButton(1:1000)
    setproperty!(sb2,:value,1)
    vbox1_2_1[1,1]=sb2

    gain_checkbox=CheckButton()
    add_button_label(gain_checkbox," x 10")
    vbox1_2_1[2,1]=gain_checkbox

    button_gain = CheckButton()
    add_button_label(button_gain,"All Channels")
    setproperty!(button_gain,:active,false)
    vbox1_2_1[1,2]=button_gain
    
		
    #THRESHOLD
    frame1_3=Frame("Threshold")
    vbox1_2[1,3]=frame1_3
    vbox1_3_1=Box(:v)
    push!(frame1_3,vbox1_3_1)
    
    #sb=SpinButton(-300:300)
    #setproperty!(sb,:value,0)
    sb=Label("0")
    push!(vbox1_3_1,sb)

    button_thres_all = CheckButton()
    add_button_label(button_thres_all,"All Channels")
    setproperty!(button_thres_all,:active,false)
    push!(vbox1_3_1,button_thres_all)
    
    button_thres = CheckButton()
    add_button_label(button_thres,"Show")
    setproperty!(button_thres,:active,false)
    push!(vbox1_3_1,button_thres)

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

    button_rb=ToggleButton()
    add_button_label(button_rb,"RubberBand")
    vbox_hold[1,3]=button_rb
    Gtk.GAccessor.active(button_rb,true)

    button_draw=ToggleButton()
    add_button_label(button_draw,"Draw")
    vbox_hold[2,3]=button_draw

    button_selection=ToggleButton()
    add_button_label(button_selection,"Selection")
    vbox_hold[3,3]=button_selection
    
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
    setproperty!(adj_sort,:value,1.0)
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

    vbox1_2[1,5]=frame1_4 |> showall

    #COLUMN 2 - Threshold slider
    vbox_slider=Box(:v)
    thres_slider = Scale(true, -300,300,1)
    adj_thres = Adjustment(thres_slider)
    setproperty!(adj_thres,:value,0)

    c_thres=Canvas(10,200)
    setproperty!(c_thres,:vexpand,false)
    
    Gtk.GAccessor.inverted(thres_slider,true)
    Gtk.GAccessor.draw_value(thres_slider,false)

    setproperty!(thres_slider,:vexpand,true)
    push!(vbox_slider,thres_slider)
    push!(vbox_slider,c_thres)
    grid[3,2]=vbox_slider
    

    #COLUMN 3 - MAXIMIZED CHANNEL PLOTTING
    
    #ROW 2
    c_grid=Grid()
    
    c2=Canvas()
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
    c3=Canvas(-1,200)     
    @guarded draw(c3) do widget
        ctx = getgc(c3)
        clear_c3(c3,1)
    end
    show(c3)
    c_grid[1,2]=c3
    setproperty!(c3,:hexpand,true)

    grid[4,2]=c_grid

    #ROW 3
    c2_slider=Scale(false, 1:16)
    adj2 = Adjustment(c2_slider)
    setproperty!(adj2,:value,1)
    grid[4,3]=c2_slider
 
    #COLUMN 3 - 16 CHANNEL DISPLAY

    #ROW 1 - Time
    s_label=Label("0")
    m_label=Label("0")
    h_label=Label("0")
    sm_label=Label(":")
    mh_label=Label(":")

    frame_time=Frame("Time Elapsed")
    grid[5,1]=frame_time
    hbox_time=ButtonBox(:h)
    push!(frame_time,hbox_time)

    push!(hbox_time,h_label)
push!(hbox_time,mh_label)
push!(hbox_time,m_label)
    push!(hbox_time,sm_label)
    push!(hbox_time,s_label)
    
    
    #ROW 2
#c=@Canvas(500,800)
c=Canvas(500)
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
    c_slider = Scale(false, 0:(div(length(r.nums)-1,16)+1))
    adj = Adjustment(c_slider)
    setproperty!(adj,:value,1)
    grid[5,3]=c_slider

    #COLUMN 4
    #ROW 2
    vbox_42=Box(:v)
    grid[6,2]=vbox_42
    
vbox_rb_upper=Box(:v)
    push!(vbox_42,vbox_rb_upper)
    
    push!(vbox_rb_upper,Label("Top Panel"))
    
    rbs=Array(RadioButton,5)
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
setproperty!(c_rb,:vexpand,true)
    
    push!(vbox_42,c_rb)
    
    vbox_rb_lower=Box(:v)
    push!(vbox_42,vbox_rb_lower)
    push!(vbox_rb_lower,Label("Lower Panel"))
    
    rbs2=Array(RadioButton,8)
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

#Table of Values Popup
table_grid=Grid()

table_list=ListStore(Int32,Int32,Int32,Int32,Bool)
for i=1:size(r.v,2)
    push!(table_list,(i,125,0,0,true))
end

table_tv=TreeView(TreeModel(table_list))
table_rtext1=CellRendererText()
table_rtext2=CellRendererText()
setproperty!(table_rtext2, :editable, true)
table_rtext3=CellRendererText()
setproperty!(table_rtext3, :editable, true)
table_rtext4=CellRendererText()
setproperty!(table_rtext4, :editable, true)
table_rtog=CellRendererToggle()
setproperty!(table_rtog, :activatable, true)

table_c1 = TreeViewColumn("Channel",table_rtext1,Dict([("text",0)]))
table_c2 = TreeViewColumn("Gain", table_rtext2, Dict([("text",1)]))
table_c3 = TreeViewColumn("Threshold", table_rtext3, Dict([("text",2)]))
table_c4 = TreeViewColumn("Reference", table_rtext4, Dict([("text",3)]))
table_c5 = TreeViewColumn("Enabled",table_rtog,Dict([("active",4)]))

push!(table_tv,table_c1)
push!(table_tv,table_c2)
push!(table_tv,table_c3)
push!(table_tv,table_c4)
push!(table_tv,table_c5)

table_scroll=ScrolledWindow()
Gtk.GAccessor.min_content_height(table_scroll,500)
Gtk.GAccessor.min_content_width(table_scroll,500)
push!(table_scroll,table_tv)

table_grid[1,1]=table_scroll

table_win=Window(table_grid)
setproperty!(table_win, :title, "Parameter List")

showall(table_win)
visible(table_win,false)

# Reference popup
ref_grid=Grid()

ref_list1=ListStore(Int32)
for i=1:size(r.v,2)
    push!(ref_list1,(i,))
end
ref_tv1=TreeView(TreeModel(ref_list1))
ref_r1=CellRendererText()
ref_c1=TreeViewColumn("New Reference:",ref_r1, Dict([("text",0)]))

ref_tv1_s=Gtk.GAccessor.selection(ref_tv1)
    
push!(ref_tv1,ref_c1)
    
ref_scroll1=ScrolledWindow()
Gtk.GAccessor.min_content_height(ref_scroll1,350)
Gtk.GAccessor.min_content_width(ref_scroll1,175)
push!(ref_scroll1,ref_tv1)

ref_list2=ListStore(Int32)
for i=1:size(r.v,2)
    push!(ref_list2,(i,))
end
ref_tv2=TreeView(TreeModel(ref_list2))
ref_r2=CellRendererText()
ref_c2=TreeViewColumn("Apply Reference To:",ref_r2, Dict([("text",0)]))

ref_tv2_s=Gtk.GAccessor.selection(ref_tv2)
Gtk.GAccessor.mode(ref_tv2_s,Gtk.GConstants.GtkSelectionMode.MULTIPLE)
    
push!(ref_tv2,ref_c2)
    
ref_scroll2=ScrolledWindow()
Gtk.GAccessor.min_content_height(ref_scroll2,350)
Gtk.GAccessor.min_content_width(ref_scroll2,175)
push!(ref_scroll2,ref_tv2)

ref_button2=Button("Select All/None")
ref_button3=Button("Apply")

ref_grid[1,1]=ref_scroll1
ref_grid[2,1]=Canvas(50,350)
ref_grid[3,1]=ref_scroll2
ref_grid[3,2]=ref_button2
ref_grid[2,3]=Canvas(50,50)
ref_grid[3,4]=ref_button3
ref_win=Window(ref_grid)
setproperty!(ref_win, :title, "Reference Channel Select")

showall(ref_win)
visible(ref_win,false)

#Bandwidth Adjustment

band_hw_frame=Frame("Hardware Filters")
band_grid=Grid()
band_hw_grid=Grid()
band_grid[1,1]=band_hw_frame
push!(band_hw_frame,band_hw_grid)

band_sb1=SpinButton(0:1000)
setproperty!(band_sb1,:value,300)
band_hw_grid[1,1]=band_sb1
band_hw_grid[2,1]=Label("Lower Bandwidth")

band_sb2=SpinButton(1000:10000)
setproperty!(band_sb2,:value,5000)
band_hw_grid[1,2]=band_sb2
band_hw_grid[2,2]=Label("Higher BandWidth")

band_sb3=SpinButton(0:1000)
setproperty!(band_sb3,:value,300)
band_hw_grid[1,3]=band_sb3
band_hw_grid[2,3]=Label("DSP High Pass")

band_b1=Button("Update")
band_hw_grid[1,4]=band_b1

band_sw_frame=Frame("Software Filters")
band_sw_grid=Grid()
band_grid[1,2]=band_sw_frame
push!(band_sw_frame,band_sw_grid)

band_sw_sb3=SpinButton(1:size(r.v,2))
setproperty!(band_sw_sb3,:value,1)
band_sw_grid[1,1]=band_sw_sb3
band_sw_grid[2,1]=Label("Channel Number")

band_sw_sb4=SpinButton(1:1)
setproperty!(band_sw_sb4,:value,1)
band_sw_grid[1,2]=band_sw_sb4
band_sw_grid[2,2]=Label("Filter Number")

band_sw_check=CheckButton()
band_sw_grid[1,3]=band_sw_check
band_sw_grid[2,3]=Label("All Channels")

filter_combo = ComboBoxText()
for choice in ["High Pass"; "Low Pass"; "BandPass"; "BandStop"]
    push!(filter_combo,choice)
end
setproperty!(filter_combo,:active,0)

band_sw_grid[1,4]=filter_combo
band_sw_grid[2,4]=Label("Filter Type")

band_sw_sb1=SpinButton(0:10000)
setproperty!(band_sw_sb1,:value,10)
band_sw_grid[1,5]=band_sw_sb1
band_sw_sb1_l=Label("High Pass Cutoff")
band_sw_grid[2,5]=band_sw_sb1_l

band_sw_sb2=SpinButton(0:10000)
setproperty!(band_sw_sb2,:value,10)
band_sw_grid[1,6]=band_sw_sb2
band_sw_sb2_l=Label("")
band_sw_grid[2,6]=band_sw_sb2_l

filter_combo_output = ComboBoxText()
for choice in ["Spikes"; "LFP"]
    push!(filter_combo_output,choice)
end
setproperty!(filter_combo_output,:active,0)
band_sw_grid[1,7]=filter_combo_output
band_sw_grid[2,7]=Label("Output of Filter")

band_sw_b1=Button("Add New")
band_sw_grid[1,8]=band_sw_b1

band_sw_b2=Button("Replace")
band_sw_grid[2,8]=band_sw_b2

band_sw_b_delete=Button("Delete")
band_sw_grid[1,9]=band_sw_b_delete

band_sw_c=Canvas(200,300)
band_sw_grid[2,10]=band_sw_c


filt_list = ListStore(String,Int32,Int32)

filt_tv = TreeView(TreeModel(filt_list))
filt_rtext2=CellRendererText()
filt_rtext3=CellRendererText()
filt_rtext4=CellRendererText()

filt_c2 = TreeViewColumn("Filter Type",filt_rtext2,Dict([("text",1)]))
filt_c3 = TreeViewColumn("Wn1",filt_rtext3,Dict([("text",2)]))
filt_c4 = TreeViewColumn("Wn2",filt_rtext4,Dict([("text",3)]))

filt_tv_s = Gtk.GAccessor.selection(filt_tv)
#Gtk.GAccessor.mode(filt_tv_s,Gtk.GConstants.GtkSelectionMode.MULTIPLE)

push!(filt_tv,filt_c2)
push!(filt_tv,filt_c3)
push!(filt_tv,filt_c4)

filt_scroll=ScrolledWindow()
Gtk.GAccessor.min_content_height(filt_scroll,500)
Gtk.GAccessor.min_content_width(filt_scroll,250)
push!(filt_scroll,filt_tv)

band_grid[2,2]=filt_scroll

band_win=Window(band_grid)
setproperty!(band_win, :title, "Filtering")

showall(band_win)
visible(band_win,false)
Gtk.visible(band_sw_sb2,false)

#SortView

sortview_handles = SpikeSorting.sort_gui(s[1].s.win+1)
visible(sortview_handles.win,false)

#=
Save Preferences Window
=#

save_grid=Grid()

save_grid[1,1]=Label(string("Save Folder: ",r.save.folder))

save_check_volt=CheckButton("Analog Voltage")
save_grid[1,2]=save_check_volt
if r.save.save_full
    setproperty!(save_check_volt,:active,true)
end

save_check_lfp=CheckButton("LFP")
save_grid[1,3]=save_check_lfp

save_check_ttlin=CheckButton("TTL input")
save_grid[1,4]=save_check_ttlin

save_pref_win=Window(save_grid)
setproperty!(save_pref_win, :title, "Saving Preferences")

showall(save_pref_win)
visible(save_pref_win,false)


#POPUP MENUS

#Enable-Disable
    popupmenu = Menu()
    popup_enable = MenuItem("Enable")
    push!(popupmenu, popup_enable)
    popup_disable = MenuItem("Disable")
    push!(popupmenu, popup_disable)
showall(popupmenu)

#Event
popup_event = Menu()
event_handles=Array(CheckMenuItemLeaf,0)
for i=1:8
    push!(event_handles,CheckMenuItem(string("Analog ",i)))
    push!(popup_event,event_handles[i])
end

for i=1:16
    push!(event_handles,CheckMenuItem(string("TTL ",i)))
    push!(popup_event,event_handles[8+i])
end

popup_event_none=MenuItem("None")
push!(popup_event,popup_event_none)
showall(popup_event)
    
    setproperty!(grid, :column_spacing, 15) 
    setproperty!(grid, :row_spacing, 15) 
win = Window(grid, "Intan.jl GUI") |> showall

#=
Spectrogram Menus
=#

popupmenu_spect = Menu()
popupmenu_spect_freq = MenuItem("Frequency Range")
popupmenu_spect_win = MenuItem("Window Size")
popupmenu_spect_overlap = MenuItem("Window Overlap")
push!(popupmenu_spect,popupmenu_spect_freq)
push!(popupmenu_spect,popupmenu_spect_win)
push!(popupmenu_spect,popupmenu_spect_overlap)

popupmenu_spect_freq_select=Menu(popupmenu_spect_freq)
spect_f_handles=Array(RadioMenuItemLeaf,0)
spect_f_options=[300; 1000; 3000; 7500; 15000]

push!(spect_f_handles,RadioMenuItem(string(spect_f_options[1])))
push!(popupmenu_spect_freq_select,spect_f_handles[1])

for i=2:5
    push!(spect_f_handles,RadioMenuItem(spect_f_handles[i-1],string(spect_f_options[i])))
    push!(popupmenu_spect_freq_select,spect_f_handles[i])
end

set_active!(spect_f_handles[5])

popupmenu_spect_win_select=Menu(popupmenu_spect_win)
spect_w_handles=Array(RadioMenuItemLeaf,0)
spect_w_options=[10; 50; 100]

push!(spect_w_handles,RadioMenuItem(string(spect_w_options[1])))
push!(popupmenu_spect_win_select,spect_w_handles[1])

for i=2:3
    push!(spect_w_handles,RadioMenuItem(spect_w_handles[i-1],string(spect_w_options[i])))
    push!(popupmenu_spect_win_select,spect_w_handles[i])
end

set_active!(spect_w_handles[1])

showall(popupmenu_spect) 

#=
Soft Scope Menus
=#

popupmenu_scope = Menu()
popupmenu_voltage=MenuItem("Voltage Scale")
popupmenu_time=MenuItem("Time Scale")
popupmenu_thres=MenuItem("Threshold")
push!(popupmenu_scope,popupmenu_voltage)
push!(popupmenu_scope,popupmenu_time)
push!(popupmenu_scope,popupmenu_thres)


popupmenu_voltage_select=Menu(popupmenu_voltage)
scope_v_handles=Array(RadioMenuItemLeaf,0)
voltage_scales=[1, 50, 100, 200, 500]
push!(scope_v_handles,RadioMenuItem(string(voltage_scales[1]))) 
push!(popupmenu_voltage_select,scope_v_handles[1])
for i=2:5
    push!(scope_v_handles,RadioMenuItem(scope_v_handles[i-1],string(voltage_scales[i]))) 
    push!(popupmenu_voltage_select,scope_v_handles[i])
end

popupmenu_time_select=Menu(popupmenu_time)
scope_t_handles=Array(RadioMenuItemLeaf,0)
time_scales=[1, 2, 3, 4, 5]
push!(scope_t_handles,RadioMenuItem(string(time_scales[1]))) 
push!(popupmenu_time_select,scope_t_handles[1])
for i=2:5
    push!(scope_t_handles,RadioMenuItem(scope_t_handles[i-1],string(time_scales[i]))) 
    push!(popupmenu_time_select,scope_t_handles[i])
end

popupmenu_thres_select=Menu(popupmenu_thres)
scope_thres_handles=Array(RadioMenuItemLeaf,0)
push!(scope_thres_handles,RadioMenuItem("On"))
push!(popupmenu_thres_select,scope_thres_handles[1])
push!(scope_thres_handles,RadioMenuItem(scope_thres_handles[1],"Off"))
push!(popupmenu_thres_select,scope_thres_handles[2])

set_active!(scope_thres_handles[2])

showall(popupmenu_scope)   


#Prepare saving headers

mkdir(r.save.folder)
mkdir(r.save.backup)
mkdir(string(r.save.backup,"thres"))
mkdir(string(r.save.backup,"gain"))
mkdir(string(r.save.backup,"cluster"))

f=open(string(r.save.backup,"backup.bin"),"w")
write(f,1)
close(f)

if r.save.save_full
    prepare_v_header(r)
    prepare_stamp_header(r)
    prepare_ttl_header(r)
else
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

sort_widgets=Sort_Widgets(button_sort1,button_sort2,button_sort3,button_sort4,check_sort1,false)
thres_widgets=Thres_Widgets(sb,thres_slider,adj_thres,button_thres_all,button_thres)
gain_widgets=Gain_Widgets(sb2,gain_checkbox,button_gain)
spike_widgets=Spike_Widgets(button_clear,button_pause)
band_widgets=Band_Widgets(band_win,band_sb1,band_sb2,band_sb3,band_b1,filter_combo,band_sw_sb1,band_sw_sb2,band_sw_sb3,band_sw_b1,band_sw_b2,band_sw_check,band_sw_sb1_l,band_sw_sb2_l,filter_combo_output,band_sw_sb4,band_sw_c,10,10,1,1,0,1,falses(size(r.v,2)),filt_tv,filt_list)
table_widgets=Table_Widgets(table_win,table_tv,table_list)
spect_widgets=Spectrogram(r.sr)
save_widgets=Save_Widgets(save_pref_win,save_check_volt,save_check_lfp,save_check_ttlin)

sleep(1.0)

sc_widgets=Single_Channel(c2,c3,getgc(c2),copy(getgc(c2)),false,RubberBand(Vec2(0.0,0.0),Vec2(0.0,0.0),Vec2(0.0,0.0),[Vec2(0.0,0.0)],false,0),1,falses(500),falses(500),false,false,button_pause,button_rb,button_draw,button_selection,(0.0,0.0),false,width(getgc(c2)),height(getgc(c2)),s[1].s.win,1.0,0.0)

    #Create type with handles to everything
handles=Gui_Handles(win,button_run,button_init,button_cal,c_slider,adj,c2_slider,adj2,
                    c,1,1,1,scales,offs,(0.0,0.0),zeros(Int64,length(r.nums)),
                    0,-1.*ones(Int64,6),
                    trues(length(r.nums)),mytime(0,h_label,0,m_label,0,s_label),
                    s[1].s.win,1,1,popupmenu,popup_event,popupmenu_spect,rbs,rbs2,scope_mat,
                    adj_thres,thres_slider,false,0.0,0.0,false,16,ClusterTemplate(convert(Int64,s[1].s.win)),
                    false,slider_sort,adj_sort,sort_list,sort_tv,
                    1,1,zeros(Int64,500),zeros(UInt32,20),
                    zeros(UInt32,500),zeros(Int64,50),ref_win,ref_tv1,
                    ref_tv2,ref_list1,ref_list2,false,SoftScope(r.sr),
                    popupmenu_scope,sort_widgets,thres_widgets,gain_widgets,spike_widgets,
                    sortview_handles,band_widgets,table_widgets,spect_widgets,save_widgets,sc_widgets,sortview_handles.buf,rand(Int8,r.sr))

#=
Template Sorting Callbacks
=#

    id = signal_connect(canvas_release_template,c2,"button-release-event",Void,(Ptr{Gtk.GdkEventButton},),false,(handles,))
    
    id = signal_connect(b1_cb_template,button_sort1,"clicked",Void,(),false,(handles,))
    add_button_label(button_sort1,"Delete Unit")
    
    id = signal_connect(b2_cb_template,button_sort2,"clicked",Void,(),false,(handles,))
    add_button_label(button_sort2,"Add Unit")
    
    id = signal_connect(b3_cb_template,button_sort3,"clicked",Void,(),false,(handles,))
    add_button_label(button_sort3,"Collect Templates")
    
    id = signal_connect(b4_cb_template,button_sort4,"clicked",Void,(),false,(handles,))
    add_button_label(button_sort4,"Show Template Bounds")
    
    setproperty!(check_sort1,:label,"Show Template")
    id = signal_connect(check_cb_template,check_sort1,"clicked",Void,(),false,(handles,))

    setproperty!(slider_sort_label,:label,"Tolerance")

id = signal_connect(unit_select_cb,sort_tv, "row-activated", Void, (Ptr{Gtk.GtkTreePath},Ptr{Gtk.GtkTreeViewColumn}), false, (handles,))
id = signal_connect(canvas_press_win,c2,"button-press-event",Void,(Ptr{Gtk.GdkEventButton},),false,(handles,))


#=
Window Callbacks
=#

id = signal_connect(win_resize_cb, win, "size-allocate",Void,(Ptr{Gtk.GdkRectangle},),false,(handles,r))


#=
ISI canvas callbacks
=#

id = signal_connect(c3_press_win,c3,"button-press-event",Void,(Ptr{Gtk.GdkEventButton},),false,(handles,))


#=
Start Button Callbacks
=#

id = signal_connect(run_cb, button_run, "clicked",Void,(),false,(handles,r,s,task,fpga))
    id = signal_connect(init_cb, button_init, "clicked", Void, (), false, (handles,r,task,fpga))
    id = signal_connect(cal_cb, button_cal, "clicked", Void, (), false, (handles,r))


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
id = signal_connect(gain_check_cb,gain_checkbox, "clicked", Void,(),false,(handles,))


#=
Threshold callbacks
=#

id = signal_connect(thres_cb,thres_slider,"value-changed",Void,(),false,(handles,))
id = signal_connect(thres_show_cb,button_thres,"clicked",Void,(),false,(handles,))


#=
Pause, Restore, and Clear Callbacks
=#

id = signal_connect(pause_cb,button_pause,"toggled",Void,(),false,(handles,))
id = signal_connect(clear_button_cb,button_clear,"clicked",Void,(),false,(handles,))
id = signal_connect(restore_button_cb,button_restore,"clicked",Void,(),false,(handles,))


#=
Event Viewer Callbacks
=#

for i=1:8
    id = signal_connect(popup_event_cb,event_handles[i],"activate",Void,(),false,(handles,i-1))
end

for i=9:24
    id = signal_connect(popup_event_cb,event_handles[i],"activate",Void,(),false,(handles,i-1))
end

id = signal_connect(popup_event_cb,popup_event_none,"activate",Void,(),false,(handles,-1))


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
Filter Callback
=#

signal_connect(band_b1_cb,band_b1,"clicked",Void,(),false,(handles,fpga))

signal_connect(band_win, :delete_event) do widget, event
    visible(band_win, false)
    true
end
id = signal_connect(band_adj_cb, op_band, "activate",Void,(),false,(handles,r))
id = signal_connect(add_filter_cb,band_sw_b1,"clicked",Void,(),false,(handles,r))
id = signal_connect(replace_filter_cb,band_sw_b2,"clicked",Void,(),false,(handles,r))
id = signal_connect(filter_type_cb,filter_combo, "changed",Void,(),false,(handles,r))
id = signal_connect(change_channel_cb,band_sw_sb3,"value-changed",Void,(),false,(handles,r))
id = signal_connect(change_wn1_cb,band_sw_sb1,"value-changed",Void,(),false,(handles,r))
id = signal_connect(change_wn2_cb,band_sw_sb2,"value-changed",Void,(),false,(handles,r))
id = signal_connect(change_filt_output_cb,filter_combo_output,"changed",Void,(),false,(handles,r))
id = signal_connect(change_pos_cb,band_sw_sb4,"value-changed",Void,(),false,(r,handles))
id = signal_connect(delete_filter_cb,band_sw_b_delete,"clicked",Void,(),false,(handles,r))

#=
Save Preferences Callbacks
=#

signal_connect(saving_pref_cb,saving_pref_,"activate",Void,(),false,(handles,r))

signal_connect(save_pref_win, :delete_event) do widget, event
    visible(save_pref_win, false)
    true
end
id=signal_connect(save_volt_cb,save_check_volt,"clicked",Void,(),false,(handles,r))
id=signal_connect(save_lfp_cb,save_check_lfp,"clicked",Void,(),false,(handles,r))
id=signal_connect(save_ttlin_cb,save_check_ttlin,"clicked",Void,(),false,(handles,r))

#=
Soft Scope Callbacks
=#

for i=1:5
    signal_connect(scope_popup_v_cb,scope_v_handles[i],"activate",Void,(),false,(handles,i-1))
end

for i=1:5
    signal_connect(scope_popup_t_cb,scope_t_handles[i],"activate",Void,(),false,(handles,i-1))
end

for i=1:2
    signal_connect(scope_popup_thres_cb,scope_thres_handles[i],"activate",Void,(),false,(handles,i-1))
end

#=
Spectrogram Callbacks
=#

for i=1:5
    signal_connect(spect_popup_freq_cb,spect_f_handles[i],"activate",Void,(),false,(handles,i-1))
end

for i=1:3
    signal_connect(spect_popup_win_cb,spect_w_handles[i],"activate",Void,(),false,(handles,i-1))
end

#=
Reference
=#

id = signal_connect(ref_cb, define_ref_, "activate",Void,(),false,(handles,r))
id = signal_connect(ref_b2_cb, ref_button2, "clicked",Void,(),false,(handles,))
id = signal_connect(ref_b3_cb, ref_button3, "clicked",Void,(),false,(handles,r))

signal_connect(ref_win, :delete_event) do widget, event
    visible(ref_win, false)
    true
end

#=
Parameter Table
=#

id = signal_connect(table_cb, define_params, "activate",Void,(),false,(handles,r))

signal_connect(table_win, :delete_event) do widget, event
    visible(table_win,false)
    true
end

id = signal_connect(table_col_cb, table_rtext2,"edited",Void,(Ptr{UInt8},Ptr{UInt8}),false,(handles,r,2))
id = signal_connect(table_col_cb, table_rtext3,"edited",Void,(Ptr{UInt8},Ptr{UInt8}),false,(handles,r,3))
id = signal_connect(table_col_cb, table_rtext4,"edited",Void,(Ptr{UInt8},Ptr{UInt8}),false,(handles,r,4))
id = signal_connect(table_en_cb, table_rtog, "toggled",Void,(Ptr{UInt8},),false,(handles,r))


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
function run_cb{T<:Sorting,I<:IC}(widgetptr::Ptr,user_data::Tuple{Gui_Handles,RHD2000,DArray{T,1,Array{T,1}},Task,DArray{I,1,Array{I,1}}})
    
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

function run_cb{R<:RHD2000,S<:Sorting,T<:Task,I<:IC}(widgetptr::Ptr,user_data::Tuple{Gui_Handles,R,Array{S,1},T,Array{I,1}})

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

function main_loop_s{T<:Sorting,I<:IC}(rhd::RHD2000,han::Gui_Handles,s::Array{T,1},task::Task,fpga::Array{I,1})
    if rhd.debug.state==false
        myread=readDataBlocks(rhd,1,s,fpga)
    else
        myread=readDataBlocks(rhd,s)
    end
    main_loop(rhd,han,s,task,myread,fpga)
end

function main_loop_par{T<:Sorting,I<:IC}(rhd::RHD2000,han::Gui_Handles,s::DArray{T,1,Array{T,1}},task::Task,fpga::DArray{I,1,Array{I,1}})
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
    do_task(task,rhd,myread)
    
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
                    (mymean,mystd)=make_cluster(han.buf.spikes,han.buf.mask,han.buf.ind,!han.buf.selected)
                
                    #Apply cluster characteristics to handles cluster
                    change_cluster(han.temp,mymean,mystd,clus)
                    setproperty!(han.adj_sort, :value, 1.0)

                    if (han.buf.count>0)&(han.sc.pause)
                        template_cluster(han,clus,mymean,mystd[:,2],mystd[:,1],1.0)
                    end

                end
                
                #Send cluster information to sorting 
                send_clus(s,han)
                backup_clus(han.temp,han.spike,rhd.save.backup)
                han.buf.c_changed=false
            end
            if han.buf.replot
                replot_all_spikes(han)
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
            if han.thres_changed
                thres_changed(han,s,fpga,rhd.save.backup)
            end
            if han.sc.show_thres
                plot_thres(han)
            end
            if han.sc.rb_active
                draw_rb(han)
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
	        clear_c2(han.sc.c2,han.spike)
                han.sc.ctx2=getgc(han.sc.c2)
                han.sc.ctx2s=copy(han.sc.ctx2)
            end
            clear_c3(han.sc.c3,han.spike)
            #Sort Button
            if han.sort_cb
                draw_templates(han)
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

        old_spike=rem(han.spike-1,han.chan_per_display)+1
        han.spike_changed=true
        
        #Highlight channel
        highlight_channel(han,old_spike)
    end       
    nothing
end

function get_cluster{T<:Sorting}(han::Gui_Handles,s::Array{T,1})
    han.temp=deepcopy(s[han.spike].c)
end

function get_cluster{T<:Sorting}(han::Gui_Handles,s::DArray{T,1,Array{T,1}})
    (nn,mycore)=get_thres_id(s,han.spike)
    
    han.temp=remotecall_fetch(((x,ss)->localpart(x)[ss].c),mycore,s,nn)
end

function backup_clus(myclus,chan,backup)

    f=open(string(backup,"/cluster/",chan,".bin"),"w")
    for i in fieldnames(myclus)
        write(f,getfield(myclus,i))
    end
    close(f)
    
    nothing
end

function send_clus{T<:Sorting}(s::Array{T,1},han::Gui_Handles)
    s[han.spike].c=deepcopy(han.temp)
    nothing
end

function send_clus{T<:Sorting}(s::DArray{T,1,Array{T,1}},han::Gui_Handles)
    (nn,mycore)=get_thres_id(s,han.spike)
    remotecall_wait(((x,tt,num)->localpart(x)[num].c=tt),mycore,s,han.temp,nn)
    nothing
end

function clear_button_cb(widget::Ptr,user_data::Tuple{Gui_Handles})

    han, = user_data
    clear_c2(han.sc.c2,han.spike)
    han.sc.ctx2=getgc(han.sc.c2)
    han.sc.ctx2s=copy(han.sc.ctx2)
    #Sort Button
    if han.sort_cb
        draw_templates(han)
    end
    
    nothing
end

function restore_button_cb(widget::Ptr,user_data::Tuple{Gui_Handles})

    han, = user_data

    if han.sc.pause
        for i=1:han.buf.ind
            han.buf.mask[i]=true
        end

        han.buf.replot=true
    end
    
    nothing
end

function init_cb{I<:IC}(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000,Task,Array{I,1}})

    han, rhd,task,fpga = user_data       
    init_board!(rhd,fpga)
    init_task(task,rhd)

    nothing
end

function init_cb{I<:IC}(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000,Task,DArray{I,1,Array{I,1}}})

    han, rhd,task,fpga = user_data       
    init_board!(rhd,fpga)
    init_task(task,rhd)

    nothing
end

function cal_cb{R<:RHD2000}(widget::Ptr, user_data::Tuple{Gui_Handles,R})

    han, rhd = user_data

    mycal=getproperty(han.cal,:active,Bool)
        
    if mycal==true
        rhd.cal=0
    else
        rhd.cal=3
    
        @inbounds for i=1:length(han.offset)
            han.offset[i]=0.0
            han.scale[i,1] = -.125
            han.scale[i,2] = -.125*.25
        end

        han.sc.s = han.scale[han.spike,1]

        setproperty!(han.gain_widgets.gainbox,:value,round(Int,han.scale[han.spike,1]*-1000)) #show gain

        han.spike_changed=true
    end

    nothing
end

function pause_cb(widgetptr::Ptr,user_data::Tuple{Gui_Handles})

    han, = user_data
    
    widget = convert(ToggleButton, widgetptr)

    if getproperty(widget,:active,Bool)
        han.sc.pause=true
        change_button_label(widget,"Resume")
        for i=1:length(han.buf.mask)
            han.buf.mask[i]=true
        end
    else
        han.sc.pause=false
        change_button_label(widget,"Pause")
        han.sc.hold=false
    end

    nothing
end

function win_resize_cb(widget::Ptr,param_tuple,user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data

    ctx=getgc(han.sc.c2)

    if (height(ctx)!=han.sc.h2)|(width(ctx)!=han.sc.w2)

        han.sc.ctx2=ctx
        han.sc.ctx2s=copy(han.sc.ctx2)
        han.sc.w2=width(han.sc.ctx2)
        han.sc.h2=height(han.sc.ctx2)
    
        setproperty!(han.adj_thres,:upper,han.sc.h2/2)
        setproperty!(han.adj_thres,:lower,-han.sc.h2/2)
    end
    
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

    ctx=getgc(han.c)
    myheight=height(ctx)

    han.mim=(event.x,event.y)

    if event.y<(myheight-300) #top

        if han.c_right_top==1 #disable enable 16

            if event.button == 1 #left click

                (inmulti,channel_num)=check_multi(han,4,4,16,event.x,event.y)

                if inmulti
                    setproperty!(han.adj2,:value,channel_num)
                    update_c2(han)
                end
                
            elseif event.button == 3 #right click

                popup(han.popup_ed,event)
            end
        elseif han.c_right_top==2 #disable enable 32

            if event.button == 1 #left click

                (inmulti,channel_num)=check_multi(han,6,6,32,event.x,event.y)
                if inmulti
                    setproperty!(han.adj2,:value,channel_num)
                    update_c2(han)
                end
                
            elseif event.button == 3 #right click

                popup(han.popup_ed,event)
            end
            
        elseif han.c_right_top==3 #disable enable 64
            
            if event.button == 1 #left click

                (inmulti,channel_num)=check_multi(han,11,6,64,event.x,event.y)
                if inmulti
                    setproperty!(han.adj2,:value,channel_num)
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
                    setproperty!(han.adj2,:value,channel_num)
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

function c3_press_win(widget::Ptr,param_tuple,user_data::Tuple{Gui_Handles})

    han, = user_data
    event = unsafe_load(param_tuple)
    
    if event.button == 1 #left click captures window
        check_c3_click(han,event.x,event.y)
    elseif event.button == 3 #right click refreshes window
    end
    nothing
end

function check_c3_click(han::Gui_Handles,x,y)

    ctx=getgc(han.sc.c3)
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
        select_unit(han)
    end
    nothing
end

function get_template_dims(han::Gui_Handles,clus)

    ctx=getgc(han.sc.c3)
    mywidth=width(ctx)

    total_clus = max(han.total_clus[han.spike]+1,5)
    
    xbounds=linspace(0.0,mywidth,total_clus+1)

    (xbounds[clus],xbounds[clus+1],0.0,130.0)
end
