

function makegui(r::RHD2000)
    
    #Button to run Intan
    button_run = @ToggleButton("Run")

    #Button to initialize Board
    button_init = @Button("Init")

    #Button for Autoscaling
    button_auto = @Button("Autoscale")

    #Calibration
    button_cal = @CheckButton("Calibrate")
    setproperty!(button_cal,:active,true)

    #16 channels at a time can be visualized on the right side
    c=@Canvas(800,800) #16 channels
    
    @guarded draw(c) do widget
    ctx = getgc(c)
    set_source_rgb(ctx,1,1,1)
    paint(ctx)
    end
    show(c)
       
    #Which 16 channels can be selected with a slider
    c_slider = @Scale(false, 0:(div(length(r.nums)-1,16)+1))
    adj = @Adjustment(c_slider)
    setproperty!(adj,:value,1)
    
    #One channel can be magnified for easier inspection
    c2=@Canvas(800,800) #Single channel to focus on
    c2_slider=@Scale(false, 1:16)
    
    @guarded draw(c2) do widget
    ctx = getgc(c2)
    set_source_rgb(ctx,1,1,1)
    paint(ctx)
    end
    show(c2)
    
    adj2 = @Adjustment(c2_slider)
    setproperty!(adj2,:value,1)

    if typeof(r.s[1].c)==ClusterWindow 
        tb1=@Label("Cluster")
        tb2=@Label("Window")
    else
        tb1=@Label("text1")
        tb2=@Label("text2")
    end

    sb=@SpinButton(-1000:1000)

    setproperty!(sb,:value,0)
    tb_threshold=@Label("Threshold")

    sb2=@SpinButton(1:1000)
    setproperty!(sb2,:value,1)

    tb_gain=@Label("Gain")

    button_gain = @CheckButton("All Channels")
    setproperty!(button_gain,:active,false)

    button_sort1 = @Button("Delete Cluster")
    button_sort2 = @Button("Delete Window")
    button_sort3 = @Button("Show Windows")
    
    #Arrangement of stuff on GUI
    grid = @Grid()
    hbox = @ButtonBox(:h)
    grid[2,1]=hbox
    push!(hbox,button_init)
    push!(hbox,button_run)
    push!(hbox,button_cal)
    push!(hbox,tb_threshold)
    push!(hbox,sb)
    hbox2=@ButtonBox(:h)
    grid[2,2]=hbox2
    push!(hbox2,tb_gain)
    push!(hbox2,sb2)
    push!(hbox2,button_gain)
    push!(hbox2,button_auto)
    hbox3=@ButtonBox(:h)
    grid[2,3]=hbox3
    push!(hbox3,tb1)
    push!(hbox3,tb2)
    push!(hbox3,button_sort1)
    push!(hbox3,button_sort2)
    push!(hbox3,button_sort3)
    grid[3,4]=c
    grid[3,5]=c_slider
    grid[2,4]=c2
    grid[2,5]=c2_slider
    setproperty!(grid, :column_spacing, 15) 
    setproperty!(grid, :row_spacing, 15) 
    win = @Window(grid, "Intan.jl GUI")
    showall(win)

    #Callback functions that interact with canvas depend on spike sorting method that is being used

    scales=ones(Float64,size(r.v,2),3)
    scales[:,2]=scales[:,2].*.25
    offs=zeros(Float64,size(r.v,2),2)
    offs[:,1]=squeeze(mean(r.v,1),1)
    offs[:,2]=offs[:,1]*.25

    #Create type with handles to everything
    handles=Gui_Handles(win,button_run,button_init,button_cal,c_slider,adj,c2_slider,adj2,c,c2,1,1,1,scales,offs,(0.0,0.0),zeros(Int64,length(r.nums),2),zeros(Int64,length(r.nums),2),sb,tb1,tb2,button_gain,sb2)
    
    #Connect Callbacks to objects on GUI
    if typeof(r.s[1].c)==ClusterWindow
        id = signal_connect(canvas_press_win,c2,"button-press-event",Void,(Ptr{Gtk.GdkEventButton},),false,(handles,r))
        id = signal_connect(canvas_release_win,c2,"button-release-event",Void,(Ptr{Gtk.GdkEventButton},),false,(handles,r))
        id = signal_connect(b1_cb_win,button_sort1,"clicked",Void,(),false,(handles,r))
        id = signal_connect(b2_cb_win,button_sort2,"clicked",Void,(),false,(handles,r))
        id = signal_connect(b3_cb_win,button_sort3,"clicked",Void,(),false,(handles,r))
    end
    id = signal_connect(run_cb, button_run, "clicked",Void,(),false,(handles,r))
    id = signal_connect(auto_cb,button_auto,"clicked",Void,(),false,(handles,r))
    id = signal_connect(update_c1, c_slider, "value-changed", Void, (), false, (handles,r))
    id = signal_connect(update_c2, c2_slider, "value-changed", Void, (), false, (handles,r))
    id = signal_connect(init_cb, button_init, "clicked", Void, (), false, (handles,r))
    id = signal_connect(cal_cb, button_cal, "clicked", Void, (), false, (handles,r))
    id = signal_connect(sb_cb,sb,"value-changed", Void, (), false, (handles,r))
    id = signal_connect(sb2_cb,sb2, "value-changed",Void,(),false,(handles,r))

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
        readDataBlocks(rhd,1)
    else
        readDataBlocks(rhd)
    end
            
    #process and output (e.g. kalman, spike triggered stim calc, etc)
    do_task(rhd.task,rhd)

    #plot spikes               
    if han.num16>0
                    
        k=16*han.num16-15
        for i=50:200:650
            for j=50:200:650
                @inbounds draw_spike(rhd,i,j,k,ctx,han.scale[k,2],han.offset[k,2])
                k+=1
                stroke(ctx)
            end
        end             
        
        reveal(han.c)
                
        if han.num>0
                        
            @inbounds draw_spike(rhd,han.spike,ctx2,han.scale[han.spike,1],han.offset[han.spike,1])                      
            stroke(ctx2)
            reveal(han.c2)                  
        end
    end

    #write to disk, clear buffers
    queueToFile(rhd,rhd.save)

    sleep(.00001)
    nothing
end

function auto_cb(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data
    
    #scale
    @inbounds han.scale[han.spike,1]=abs(1./mean(rhd.v[:,han.spike]))
    @inbounds han.scale[han.spike,2]=.25*han.scale[han.spike,1]
    @inbounds han.scale[han.spike,3]=han.scale[han.spike,1]

    @inbounds han.offset[han.spike,1]=mean(han.scale[han.spike,1].*rhd.v[:,han.spike])
    @inbounds han.offset[han.spike,2]=mean(han.scale[han.spike,2].*rhd.v[:,han.spike])

    nothing 
end

function update_c1(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})
    
    han, rhd = user_data 
    han.num16=getproperty(han.adj,:value,Int64) # 16 channels
    
    clear_c(han.c)
    clear_c(han.c2)
    
    if han.num16>0
        han.spike=16*han.num16-16+han.num
       
    end

    #Audio output
    selectDacDataStream(rhd.fpga[1],0,div(han.spike-1,32))
    selectDacDataChannel(rhd.fpga[1],0,rem(han.spike-1,32))
    
    nothing    
end

function update_c2(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data

    han.num=getproperty(han.adj2, :value, Int64) # primary display

    clear_c(han.c2)

    if han.num16>0
        han.spike=16*han.num16-16+han.num
    end

    #update threshold
    setproperty!(han.sb,:value,round(Int64,rhd.s[han.spike].thres))

    #Audio output
    selectDacDataStream(rhd.fpga[1],0,div(han.spike-1,32))
    selectDacDataChannel(rhd.fpga[1],0,rem(han.spike-1,32))
    
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
        han.scale[:,1]=abs(1./mean(rhd.v,1)')
        han.scale[:,2]=.25*han.scale[:,1]
        han.scale[:,3]=han.scale[:,1]
    end

    nothing
end

function sb_cb(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data

    rhd.s[han.spike].thres=getproperty(han.sb,:value,Int)

    nothing
end

function sb2_cb(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data

    mygain=getproperty(han.gain,:active,Bool)

    gainval=getproperty(han.gainbox,:value,Int)

    if mygain==true
        han.scale[:,1]=gainval/100
        han.scale[:,2]=.25*gainval/100
        han.scale[:,3]=gainval/100

        @inbounds han.offset[:,1]=mean(gainval/100.*rhd.v,1)
        @inbounds han.offset[:,2]=han.offset[:,1].*.25
    else
        han.scale[han.spike,1]=gainval/100
        han.scale[han.spike,2]=.25*gainval/100
        han.scale[han.spike,3]=gainval/100

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
        myx=collect(51:12:600)
        x1=indmin(abs(myx-han.mi[1]))
        x2=indmin(abs(myx-event.x))
        s=han.scale[han.spike,1]
        o=han.offset[han.spike,1]
        y1=(han.mi[2]-400+o)/s
        y2=(event.y-400+o)/s
    
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
        
    #loop over clusters
    for i=1:length(rhd.s[han.spike].c.win)
        #loop over windows
        for j=1:length(rhd.s[han.spike].c.win[i])

            x1=rhd.s[han.spike].c.win[i][j].x1
            x2=rhd.s[han.spike].c.win[i][j].x2
            y1=rhd.s[han.spike].c.win[i][j].y1
            y2=rhd.s[han.spike].c.win[i][j].y2
            move_to(ctx,x1*12+50,y1*han.scale[han.spike,1]+400-han.offset[han.spike,1])
            line_to(ctx,x2*12+50,y2*han.scale[han.spike,1]+400-han.offset[han.spike,1])
            set_line_width(ctx,5.0)
            select_color(ctx,i+1)
            stroke(ctx)
        end
    end
     
    reveal(han.c2)

    nothing
end
