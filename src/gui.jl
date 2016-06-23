

function makegui(r::RHD2000)

    #GUI ARRANGEMENT
    grid = @Grid()

    #COLUMN 1 - control buttons
	
    #ROW 1
	
    #ROW 2
    vbox1_2=@ButtonBox(:v)
    grid[1,2]=vbox1_2
	
    frame_control=@Frame("Control")
    push!(vbox1_2,frame_control)
    vbox_control = @ButtonBox(:v)
    push!(frame_control,vbox_control)
    
    button_init = @Button("Init")
    push!(vbox_control,button_init)
    
    button_run = @ToggleButton("Run")
    push!(vbox_control,button_run)
    
    button_cal = @CheckButton("Calibrate")
    setproperty!(button_cal,:active,true)
    push!(vbox_control,button_cal)

    #GAIN
    frame1_2=@Frame("Gain")
    push!(vbox1_2,frame1_2)
    vbox1_2_1=@ButtonBox(:v)
    push!(frame1_2,vbox1_2_1)
    
    sb2=@SpinButton(1:1000)
    setproperty!(sb2,:value,1)
    push!(vbox1_2_1,sb2)
    
    button_gain = @CheckButton("All Channels")
    setproperty!(button_gain,:active,false)
    push!(vbox1_2_1,button_gain)
    
    button_auto = @Button("Autoscale")
    push!(vbox1_2_1,button_auto)
	
	
    #THRESHOLD
    frame1_3=@Frame("Threshold")
    push!(vbox1_2,frame1_3)
    vbox1_3_1=@ButtonBox(:v)
    push!(frame1_3,vbox1_3_1)
    
    sb=@SpinButton(-10000:10000)
    setproperty!(sb,:value,0)
    push!(vbox1_3_1,sb)

    button_thres_all = @CheckButton("All Channels")
    setproperty!(button_thres_all,:active,false)
    push!(vbox1_3_1,button_thres_all)
    
    button_thres = @CheckButton("Show")
    setproperty!(button_thres,:active,false)
    push!(vbox1_3_1,button_thres)
    
    #CLUSTER
    frame1_4=@Frame("Clustering")
    push!(vbox1_2,frame1_4)
    vbox1_3_2=@ButtonBox(:v)
    push!(frame1_4,vbox1_3_2)

    if typeof(r.s[1].c)==ClusterWindow 
        tb1=@Label("Cluster")
        tb2=@Label("Window")
    else
        tb1=@Label("text1")
        tb2=@Label("text2")
    end
    push!(vbox1_3_2,tb1)
    push!(vbox1_3_2,tb2)
    
    button_sort1 = @Button("Delete Cluster")
    button_sort2 = @Button("Delete Window")
    button_sort3 = @Button("Show Windows")
    
    push!(vbox1_3_2,button_sort1)
    push!(vbox1_3_2,button_sort2)
    push!(vbox1_3_2,button_sort3)

    #COLUMN 2 - MAXIMIZED CHANNEL PLOTTING
    
    #ROW 2
    c2=@Canvas(500,800)     
    @guarded draw(c2) do widget
    ctx = getgc(c2)
    clear_c2(c2,1)
    end
    show(c2)
    grid[2,2]=c2

    #ROW 3
    c2_slider=@Scale(false, 1:16)
    adj2 = @Adjustment(c2_slider)
    setproperty!(adj2,:value,1)
    grid[2,3]=c2_slider
 
    #COLUMN 3 - 16 CHANNEL DISPLAY

    #ROW 1 - Time
    s_label=@Label("0")
    m_label=@Label("0")
    h_label=@Label("0")
    sm_label=@Label(":")
    mh_label=@Label(":")

    frame_time=@Frame("Time Elapsed")
    grid[3,1]=frame_time
    hbox_time=@ButtonBox(:h)
    push!(frame_time,hbox_time)

    push!(hbox_time,h_label)
    push!(hbox_time,mh_label)
    push!(hbox_time,m_label)
    push!(hbox_time,sm_label)
    push!(hbox_time,s_label)
    
    
    #ROW 2
    c=@Canvas(500,800)  
    @guarded draw(c) do widget
        ctx = getgc(c)
        set_source_rgb(ctx,0.0,0.0,0.0)
        set_operator(ctx,Cairo.OPERATOR_SOURCE)
        paint(ctx)
    end
    show(c)   
    grid[3,2]=c

    #ROW 3
    #Which 16 channels can be selected with a slider
    c_slider = @Scale(false, 0:(div(length(r.nums)-1,16)+1))
    adj = @Adjustment(c_slider)
    setproperty!(adj,:value,1)
    grid[3,3]=c_slider

    #COLUMN 4
    #ROW 2
    vbox_42=@Box(:v)
    grid[4,2]=vbox_42
    
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

    c_rb=@Canvas(40,400)

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
    save_ref_ = @MenuItem("Save Current Configuration")
    push!(refmenu,save_ref_)
    load_ref_ = @MenuItem("Load Configuration")
    push!(refmenu,load_ref_)
	
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
    
    mb = @MenuBar()
    push!(mb,saveopts)
    push!(mb,sortopts)
    push!(mb,refopts)
    push!(mb,exopts) 
    grid[2,1]=mb


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
    win = @Window(grid, "Intan.jl GUI")
showall(win)

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
    offs=zeros(Float64,size(r.v,2),2)
offs[:,1]=squeeze(mean(r.v,1),1)
offs[:,2]=offs[:,1]*.2

scope_mat=ones(Float64,500,3)

for i=1:500
    scope_mat[i,1]=550.0
    scope_mat[i,2]=650.0
    scope_mat[i,3]=750.0
end

    #Create type with handles to everything
handles=Gui_Handles(win,button_run,button_init,button_cal,c_slider,adj,c2_slider,adj2,c,c2,1,1,1,scales,offs,(0.0,0.0),(0.0,0.0),zeros(Int64,length(r.nums),2),zeros(Int64,length(r.nums),2),sb,tb1,tb2,button_gain,sb2,0,button_thres_all,-1.*ones(Int64,6),trues(length(r.nums)),false,mytime(0,h_label,0,m_label,0,s_label),r.s[1].s.win,1,1,popupmenu,popup_event,rbs,rbs2,scope_mat)

    #Connect Callbacks to objects on GUI
if typeof(r.s[1].c)==ClusterWindow
        id = signal_connect(canvas_press_win,c2,"button-press-event",Void,(Ptr{Gtk.GdkEventButton},),false,(handles,r))
        id = signal_connect(canvas_release_win,c2,"button-release-event",Void,(Ptr{Gtk.GdkEventButton},),false,(handles,r))
        id = signal_connect(b1_cb_win,button_sort1,"clicked",Void,(),false,(handles,r))
        id = signal_connect(b2_cb_win,button_sort2,"clicked",Void,(),false,(handles,r))
        id = signal_connect(b3_cb_win,button_sort3,"clicked",Void,(),false,(handles,r))
    elseif typeof(r.s[1].c)==ClusterTemplate
	
	end

    id = signal_connect(thres_show_cb,button_thres,"clicked",Void,(),false,(handles,r))
id = signal_connect(c_popup_select,c,"button-press-event",Void,(Ptr{Gtk.GdkEventButton},),false,(handles,r))
    id = signal_connect(run_cb, button_run, "clicked",Void,(),false,(handles,r))
    id = signal_connect(auto_cb,button_auto,"clicked",Void,(),false,(handles,r))
    id = signal_connect(update_c1, c_slider, "value-changed", Void, (), false, (handles,r))
    id = signal_connect(update_c2_cb, c2_slider, "value-changed", Void, (), false, (handles,r))
    id = signal_connect(init_cb, button_init, "clicked", Void, (), false, (handles,r))
    id = signal_connect(cal_cb, button_cal, "clicked", Void, (), false, (handles,r))
    id = signal_connect(sb_cb,sb,"value-changed", Void, (), false, (handles,r))
id = signal_connect(sb2_cb,sb2, "value-changed",Void,(),false,(handles,r))
id = signal_connect(popup_enable_cb,popup_enable,"activate",Void,(),false,(handles,r))
id = signal_connect(popup_disable_cb,popup_disable,"activate",Void,(),false,(handles,r))
id = signal_connect(export_plex_cb, export_plex_, "activate",Void,(),false,(handles,r))
id = signal_connect(export_jld_cb, export_jld_, "activate",Void,(),false,(handles,r))
id = signal_connect(export_mat_cb, export_mat_, "activate",Void,(),false,(handles,r))
id = signal_connect(save_config_cb, save_sort_, "activate",Void,(),false,(handles,r))
id = signal_connect(load_config_cb, load_sort_, "activate",Void,(),false,(handles,r))

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

handles  
end

#Drawing
function run_cb(widgetptr::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    widget = convert(ToggleButton, widgetptr)
	          
    @async if getproperty(widget,:active,Bool)==true
        
        #unpack tuple
        han, rhd = user_data
        
        #get context
        ctx = getgc(han.c)
        ctx2 = getgc(han.c2)
        
	if rhd.debug.state==false
            for fpga in rhd.fpga
                runBoard(fpga)
            end
        end

        while getproperty(widget,:active,Bool)==true
           main_loop(rhd,han,ctx,ctx2) 
        end       
    end
        
    nothing
end

function main_loop(rhd::RHD2000,han::Gui_Handles,ctx,ctx2)
    #get spikes and sort
    if rhd.debug.state==false
        myread=readDataBlocks(rhd,1)
    else
        myread=readDataBlocks(rhd)
    end
            
    #process and output (e.g. kalman, spike triggered stim calc, etc)
    do_task(rhd.task,rhd,myread)

    #plot spikes    
    if myread
	if han.num16>0

            #top right
            if han.c_right_top==1
                draw_spike16(rhd,han,ctx)
            elseif han.c_right_top==2
                draw_spike32(rhd,han,ctx)
            elseif han.c_right_top==3
            elseif han.c_right_top==4
            elseif han.c_right_top==5
            else
                
            end

            #bottom right
            if han.c_right_bottom==1
	        plot_events(rhd,han,han.draws)
            elseif han.c_right_bottom==2
                draw_raster16(rhd,han,ctx)
            elseif han.c_right_bottom==3
                draw_raster32(rhd,han,ctx)
            elseif han.c_right_bottom==4
                draw_scope(rhd,han,ctx)
            elseif han.c_right_bottom==5

            elseif han.c_right_bottom==6
                draw_raster64(rhd,han,ctx)
            else
                
            end

            update_time(rhd,han)         
	    reveal(han.c)
                
	    if han.num>0                     
		draw_spike(rhd,han,ctx2)
	    end
	end
	reveal(han.c2)
	han.draws+=1
	if han.draws>500
	    han.draws=0
	    clear_c(han)
	    clear_c2(han.c2,han.spike)

            #Display threshold if box checked
            if han.show_thres==true
                plot_thres(han,rhd,rhd.s[1].d)
            end
	    #highlight_channel(han,rhd)
	end
	#write to disk, clear buffers
        queueToFile(rhd,rhd.save)
    end
    sleep(.00001)
    nothing
end

function auto_cb(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data
    
    #scale
    @inbounds han.scale[han.spike,1]=-1*abs(1./mean(rhd.v[:,han.spike]))
    @inbounds han.scale[han.spike,2]=.2*han.scale[han.spike,1]

    @inbounds han.offset[han.spike,1]=mean(han.scale[han.spike,1].*rhd.v[:,han.spike])
    @inbounds han.offset[han.spike,2]=mean(han.scale[han.spike,2].*rhd.v[:,han.spike])

    nothing 
end

function update_c1(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})
    
    han, rhd = user_data 
    han.num16=getproperty(han.adj,:value,Int64) # 16 channels

    if han.num16>0
        han.spike=16*han.num16-16+han.num      
    end
    
    clear_c(han)
    clear_c2(han.c2,han.spike)

    #Audio output
    selectDacDataStream(rhd.fpga[1],0,div(han.spike-1,32))
    selectDacDataChannel(rhd.fpga[1],0,rem(han.spike-1,32))

    #Display Gain
    setproperty!(han.gainbox,:value,round(Int,han.scale[han.spike,1]*-1000))

  

    #Show which channel is highligted on 16 channel display
    #highlight_channel(han,rhd)
    
    nothing    
end

function update_c2_cb(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data
    update_c2(han,rhd)
    nothing
end

function update_c2(han::Gui_Handles,rhd::RHD2000)
    
    han.num=getproperty(han.adj2, :value, Int64) # primary display

    if han.num16>0
        han.spike=16*han.num16-16+han.num
    end

    clear_c2(han.c2,han.spike)
    
    #update threshold
    setproperty!(han.sb,:value,round(Int64,rhd.s[han.spike].thres))

    #Audio output
    selectDacDataStream(rhd.fpga[1],0,div(han.spike-1,32))
    selectDacDataChannel(rhd.fpga[1],0,rem(han.spike-1,32))

    #Display Gain
    setproperty!(han.gainbox,:value,round(Int,han.scale[han.spike,1]*-1000))

    #Show which channel is highlighted on 16 channel display
    #highlight_channel(han,rhd)
    
    nothing
end

function init_cb(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data       
    init_board!(rhd)

    #Initialize Task
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

        #scale
        han.scale[:,1]=-1.*abs(1./mean(rhd.v,1)')
        han.scale[:,2]=.2*han.scale[:,1]
        setproperty!(han.gainbox,:value,round(Int,han.scale[han.spike,1]*-1000)) #show gain
        setproperty!(han.sb,:value,round(Int64,rhd.s[han.spike].thres)) #show threshold
    end

    nothing
end

function update_time(rhd::RHD2000,han::Gui_Handles)

    total_seconds=convert(Int64,div(rhd.fpga[1].time[1],rhd.fpga[1].sampleRate))

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

function highlight_channel(han::Gui_Handles,rhd::RHD2000)

    ctx = getgc(han.c)
    
    if han.num16>0
        myy=rem(han.num-1,4)*125+1
        myx=div(han.num-1,4)*125+1
		
	move_to(ctx,myx,myy)
	line_to(ctx,myx+124,myy)
	line_to(ctx,myx+124,myy+124)
	line_to(ctx,myx,myy+124)
	line_to(ctx,myx,myy)
        
	set_source_rgb(ctx,1,0,0)
	stroke(ctx)
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

    thres=rhd.s[han.spike].thres
    move_to(ctx,1,thres*han.scale[han.spike,1]+300-han.offset[han.spike,1])
    line_to(ctx,500,thres*han.scale[han.spike,1]+300-han.offset[han.spike,1])

    move_to(ctx,1,-1*thres*han.scale[han.spike,1]+300-han.offset[han.spike,1])
    line_to(ctx,500,-1*thres*han.scale[han.spike,1]+300-han.offset[han.spike,1])

    set_source_rgb(ctx,1.0,1.0,1.0)
    stroke(ctx)
    
    nothing
end

function plot_thres(han::Gui_Handles,rhd::RHD2000,d::DetectNeg)

    ctx = getgc(han.c2)

    thres=rhd.s[han.spike].thres
    move_to(ctx,1,thres*han.scale[han.spike,1]+300-han.offset[han.spike,1])
    line_to(ctx,500,thres*han.scale[han.spike,1]+300-han.offset[han.spike,1])
    set_source_rgb(ctx,1.0,1.0,1.0)
    stroke(ctx)
    
    nothing
end

function sb_cb(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data

    mythres=getproperty(han.sb,:value,Int)
    
    if getproperty(han.thres_all,:active,Bool)      
        @inbounds for i=1:length(rhd.s)
            rhd.s[i].thres=mythres
        end    
    else
        @inbounds rhd.s[han.spike].thres=mythres
    end

    nothing
end

function sb2_cb(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data

    mygain=getproperty(han.gain,:active,Bool)

    gainval=getproperty(han.gainbox,:value,Int)

    if mygain==true
        han.scale[:,1]=-1.*gainval/1000
        han.scale[:,2]=-.2*gainval/1000

        @inbounds han.offset[:,1]=mean(gainval/1000.*rhd.v,1)
        @inbounds han.offset[:,2]=han.offset[:,1].*.2
    else
        han.scale[han.spike,1]=-1*gainval/1000
        han.scale[han.spike,2]=-.2*gainval/1000

        @inbounds han.offset[han.spike,1]=mean(han.scale[han.spike,1].*rhd.v[:,han.spike])
        @inbounds han.offset[han.spike,2]=mean(han.scale[han.spike,2].*rhd.v[:,han.spike])
    end

    nothing
end

#=
Window Discriminator Spike Sorting
=#

function canvas_press_win(widget::Ptr,param_tuple,user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data
    event = unsafe_load(param_tuple)
    
    if event.button == 1 #left click captures window
        han.mi=(event.x,event.y)
        rubberband_start(han.c2,event.x,event.y)
    elseif event.button == 2 #middle click cycles through clusters
        #go to next cluster
        clus=han.var1[han.spike,2]+1

        if clus==han.var1[han.spike,1]+2
            han.var1[han.spike,2]=0
            han.var2[han.spike,1]=0
        elseif clus==han.var1[han.spike,1]+1
            #create new cluster
            han.var1[han.spike,2]=clus
            han.var2[han.spike,1]=0
        else
            han.var1[han.spike,2]=clus
            han.var2[han.spike,1]=length(rhd.s[han.spike].c.win)
        end
            
        #reset currently selected window to zero
        han.var2[han.spike,2]=0

        setproperty!(han.tb1,:label,string("Cluster: ",han.var1[han.spike,2]))
        setproperty!(han.tb2,:label,"Window: 0")
        
        #get number of windows from cluster
    elseif event.button == 3 #right click cycles through windows in given cluster
        #go to next window
        win=han.var2[han.spike,2]+1

        if win==han.var2[han.spike,1]+2
            han.var2[han.spike,2]=0
        elseif win==han.var1[han.spike,1]+1
            #create new window
            han.var2[han.spike,2]=win
        else
            han.var2[han.spike,2]=win
        end
        
        setproperty!(han.tb2,:label,string("Window: ",han.var2[han.spike,2]))
    end  
    nothing
end

function canvas_release_win(widget::Ptr,param_tuple,user_data::Tuple{Gui_Handles,RHD2000})

    event = unsafe_load(param_tuple)
    if event.button==1
        han, rhd = user_data
        event = unsafe_load(param_tuple)
    
        #Convert canvas coordinates to voltage vs time coordinates
        increment=div(500,han.wave_points)
        myx=collect(1:increment:500)
        x1=indmin(abs(myx-han.mi[1]))
        x2=indmin(abs(myx-event.x))
        s=han.scale[han.spike,1]
        o=han.offset[han.spike,1]
        y1=(han.mi[2]-300+o)/s
        y2=(event.y-300+o)/s
    
        #ensure that left most point is first
        if x1>x2
            x=x1
            x1=x2
            x2=x
            y=y1
            y1=y2
            y2=y
        end

        #If this is distributed, it is going to be *really* slow
        #because it will be sending over the entire DArray from whatever processor
        #Change this so it is just communicating with the cluster part; JNeuron does something similar
        if (han.var1[han.spike,2]==0)||(han.var2[han.spike,2]==0) #do nothing if zeroth cluster or window      
        elseif (length(rhd.s[han.spike].c.win) < han.var1[han.spike,2]) #new cluster
            push!(rhd.s[han.spike].c.win,[SpikeSorting.mywin(x1,x2,y1,y2)])
            push!(rhd.s[han.spike].c.hits,0)
            han.var1[han.spike,1]+=1
            han.var2[han.spike,1]+=1
        elseif length(rhd.s[han.spike].c.win[han.var1[han.spike,2]]) < han.var2[han.spike,2] #new window
            push!(rhd.s[han.spike].c.win[han.var1[han.spike,2]],SpikeSorting.mywin(x1,x2,y1,y2))
            han.var2[han.spike,1]+=1
        else #replace old window
            rhd.s[han.spike].c.win[han.var1[han.spike,2]][han.var2[han.spike,2]]=SpikeSorting.mywin(x1,x2,y1,y2)
        end
    end
    
    nothing
end

#Delete clusters
function b1_cb_win(widgetptr::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data

    if (han.var1[han.spike,2]==0)||(han.var1[han.spike,2]>han.var1[han.spike,1]) #do nothing if zeroth cluster selected      
    else
        deleteat!(rhd.s[han.spike].c.win,han.var1[han.spike,2])
        pop!(rhd.s[han.spike].c.hits)
        han.var1[han.spike,1]-= 1
        han.var1[han.spike,2] = 0
        han.var2[han.spike,1] = 0
        han.var2[han.spike,2] = 0
        setproperty!(han.tb1,:label,string("Cluster: ",han.var1[han.spike,2]))
        setproperty!(han.tb2,:label,"Window: 0")
    end
    nothing
end

function b2_cb_win(widgetptr::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data 

    if (han.var2[han.spike,2]==0)||(han.var2[han.spike,2]>han.var2[han.spike,1]) #do nothing if zeroth window
    else
        deleteat!(rhd.s[han.spike].c.win[han.var1[han.spike,2]],han.var2[han.spike,2])
        han.var2[han.spike,1]-= 1
        han.var2[han.spike,2] = 0
        setproperty!(han.tb2,:label,"Window: 0")
    end
    
    nothing
end

#Display Windows
function b3_cb_win(widgetptr::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data   
    ctx = getgc(han.c2)

    increment=div(500,han.wave_points)
        
    #loop over clusters
    for i=1:length(rhd.s[han.spike].c.win)
        #loop over windows
        for j=1:length(rhd.s[han.spike].c.win[i])

            x1=(rhd.s[han.spike].c.win[i][j].x1-1)*increment+1
            x2=(rhd.s[han.spike].c.win[i][j].x2-1)*increment+1
            y1=rhd.s[han.spike].c.win[i][j].y1
            y2=rhd.s[han.spike].c.win[i][j].y2
            move_to(ctx,x1,y1*han.scale[han.spike,1]+300-han.offset[han.spike,1])
            line_to(ctx,x2,y2*han.scale[han.spike,1]+300-han.offset[han.spike,1])
            set_line_width(ctx,5.0)
            select_color(ctx,i+1)
            stroke(ctx)
        end
    end
     
    reveal(han.c2)

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

    file = jldopen(filepath, "w")
    
    write(file, "Gain", han.scale)
    write(file, "Offset", han.offset)
    write(file, "Sorting", rhd.s)
    write(file, "Enabled", han.enabled)

    close(file)

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

        e=read(file,"Enabled")

        for i=1:length(e)
            han.enabled[i]=e[i]
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

    han.mim=(event.x,event.y)

    if event.y<500 #top

        if han.c_right_top==1 #disable enable 16

            if event.button == 1 #left click

                (inmulti,channel_num)=check_multi16(event.x,event.y)

                if inmulti
                    setproperty!(han.adj2,:value,channel_num)
                    update_c2(han,rhd)
                end
                
            elseif event.button == 3 #right click

                popup(han.popup_ed,event)

            end

        elseif han.c_right_top==2 #disable enable 32

            if event.button == 1 #left click

                (inmulti,channel_num)=check_multi32(event.x,event.y)

                if inmulti
                    setproperty!(han.adj2,:value,channel_num)
                    update_c2(han,rhd)
                end
                
            elseif event.button == 3 #right click

                popup(han.popup_ed,event)

            end
            
        elseif han.c_right_top==3 #disable enable 64

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

        elseif han.c_right_bottom==5 #disable enable 64

        elseif han.c_right_bottom==6 #64 channel raster - nothing

        else

        end            
    end
    
    nothing
end

function check_multi16(x,y)

    count=1
    inmulti=false
    for i in 125:125:500, j in 125:125:500 #x
        if (x<i)&(y<j)
            inmulti=true
            break
        end
        count+=1
    end
    (inmulti,count)
end

function check_multi32(x,y)

    count=1
    inmulti=false
    for i in 84:83:499, j in 84:83:499
        if (x<i)&(y<j)
            inmulti=true
            break
        end
        count+=1
    end
    (inmulti,count)
end

function popup_enable_cb(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})
    
    han, rhd = user_data

    if han.c_right_top==1 #16 channel
        (inmulti,count)=check_multi16(han.mim[1],han.mim[2])
    elseif han.c_right_top==2 # 32 channel
        (inmulti,count)=check_multi32(han.mim[1],han.mim[2])
    else #64 channel
        (inmulti,count)=check_multi32(han.mim[1],han.mim[2])
    end

    if inmulti
        if han.c_right_top==1 #16 channel
            han.enabled[16*han.num16-16+count]=true
        elseif han.c_right_top==2 #32 channel
            han.enabled[32*div(han.num16+1,2)-32+count]=true
        else #64 channel
            
        end
    end

    nothing
end

function popup_disable_cb(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})
    
    han, rhd = user_data

    if han.c_right_top==1 #16 channel
        (inmulti,count)=check_multi16(han.mim[1],han.mim[2])
    elseif han.c_right_top==2 # 32 channel
        (inmulti,count)=check_multi32(han.mim[1],han.mim[2])
    else #64 channel
        (inmulti,count)=check_multi32(han.mim[1],han.mim[2])
    end

    if inmulti
        if han.c_right_top==1 #16 channel
            han.enabled[16*han.num16-16+count]=false
        elseif han.c_right_top==2 #32 channel
             han.enabled[32*div(han.num16+1,2)-32+count]=false
        else #64 channel
            
        end
    end

    nothing
end

function popup_event_cb(widgetptr::Ptr,user_data::Tuple{Gui_Handles,RHD2000,Int64})

    han, rhd, event_id = user_data

    chan_id=1
    if han.mim[2]<550
        chan_id=1
    elseif han.mim[2]<600
        chan_id=2
    elseif han.mim[2]<650
        chan_id=3
    elseif han.mim[2]<700
        chan_id=4
    elseif han.mim[2]<750
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
    clear_c(han)
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
