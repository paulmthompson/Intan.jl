

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

    s_slider = @Scale(true, 1:10)
    adj3 = @Adjustment(s_slider)
    setproperty!(adj3,:value,1)

    #Arrangement of stuff on GUI
    grid = @Grid()
    grid[1,2]=s_slider
    hbox = @ButtonBox(:h)
    grid[2,1]=hbox
    push!(hbox,button_init)
    push!(hbox,button_auto)
    push!(hbox,button_run)
    push!(hbox,button_cal)
    grid[3,2]=c
    grid[3,3]=c_slider
    grid[2,2]=c2
    grid[2,3]=c2_slider
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
    handles=Gui_Handles(win,button_run,button_init,button_cal,c_slider,adj,c2_slider,adj2,c,c2,s_slider,adj3,1,1,1,scales,offs,(0.0,0.0))
    
    #Connect Callbacks to objects on GUI
    if typeof(r.s[1].c)==ClusterWindow
        id = signal_connect(canvas_press_win,c2,"button-press-event",Void,(Ptr{Gtk.GdkEventButton},),false,(handles,r))
        id =signal_connect(canvas_release_win,c2,"button-release-event",Void,(Ptr{Gtk.GdkEventButton},),false,(handles,r))
    end
    id = signal_connect(run_cb, button_run, "clicked",Void,(),false,(handles,r))
    id = signal_connect(auto_cb,button_auto,"clicked",Void,(),false,(handles,r))
    id = signal_connect(update_c1, c_slider, "value-changed", Void, (), false, (handles,))
    id = signal_connect(update_c2, c2_slider, "value-changed", Void, (), false, (handles,))
    id = signal_connect(update_scale, s_slider, "value-changed", Void, (), false, (handles,r))
    id = signal_connect(init_cb, button_init, "clicked", Void, (), false, (handles,r))
    id = signal_connect(cal_cb, button_cal, "clicked", Void, (), false, (handles,r))

    #Initialize Task
    init_task(r.task,r)

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
            runBoard(rhd)
        end

        while getproperty(widget,:active,Bool)==true
            
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
                    end
                end
              
                stroke(ctx);
                reveal(han.c);
                
                if han.num>0
                        
                    @inbounds draw_spike(rhd,han.spike,ctx2,han.scale[han.spike,1],han.offset[han.spike,1])                      
                    stroke(ctx2);
                    reveal(han.c2);                    
                end
            end

            #write to disk, clear buffers
            queueToFile(rhd,rhd.save)

            sleep(.00001)
        end        
    end
        
    nothing
end

function update_scale(widgetptr::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data

    @inbounds han.scale[han.spike,1]=getproperty(han.adj3,:value,Float64)*han.scale[han.spike,3]
    @inbounds han.scale[han.spike,2]=han.scale[han.spike,1]*.25

    @inbounds han.offset[han.spike,1]=mean(han.scale[han.spike,1].*rhd.v[:,han.spike])
    @inbounds han.offset[han.spike,2]=mean(han.scale[han.spike,2].*rhd.v[:,han.spike])

    clear_c(han.c2)
        
    nothing
end

function auto_cb(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data
    han.scale[:,3]=mean(rhd.v,1)'

    nothing 
end

function update_c1(widget::Ptr,user_data::Tuple{Gui_Handles})
    
    han, = user_data 
    han.num16=getproperty(han.adj,:value,Int64) # 16 channels
    
    clear_c(han.c)
    clear_c(han.c2)
    
    if han.num16>0
        han.spike=16*han.num16-16+han.num
        
        #put scale bar in appropriate position
        @inbounds setproperty!(han.adj3,:value,han.scale[han.spike])
    end

    nothing    
end

function update_c2(widget::Ptr,user_data::Tuple{Gui_Handles})

    han, = user_data

    han.num=getproperty(han.adj2, :value, Int64) # primary display

    clear_c(han.c2)

    if han.num16>0
        han.spike=16*han.num16-16+han.num

        #put scale bar in appropriate position
        @inbounds setproperty!(han.adj3,:value,han.scale[han.spike])
    end
    
    nothing
end

function init_cb(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data       
    init_board!(rhd)

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
        han.scale[:,1]=1./mean(rhd.v,1)'
        han.scale[:,2]=.25*han.scale[:,1]
        han.scale[:,3]=1./mean(rhd.v,1)'
    end

    nothing
end

function canvas_press_win(widget::Ptr,param_tuple,user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data
    event = unsafe_load(param_tuple)
    
    if event.button == 1 #left click captures window
        han.mi=(event.x,event.y)
    elseif event.button == 2 #right click cycles through clusters
        
    elseif event.button == 3 #middle click cycles through windows in given cluster
        
    end
    
    nothing
end

function canvas_release_win(widget::Ptr,param_tuple,user_data::Tuple{Gui_Handles,RHD2000})
        
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
            
    if length(rhd.s[han.spike].c.win)==0
        push!(rhd.s[han.spike].c.win,[SpikeSorting.mywin(x1,x2,y1,y2)])
    end
    
    nothing
end

function test_data!(rhd::RHD2000)

    num_channels=size(rhd.v,2)
    
    #Create fake data for 1) analog input 2) output Spike buffer 
    # 3) output number buffer
    for i=1:num_channels
        for j=1:10
            ind=rand(1:SAMPLES_PER_DATA_BLOCK-50,1)[1]
            rhd.buf[j,i]=Spike(ind:(ind+49),1) 
        end
    end

    #random input
    rhd.v[:] = rand(1:100,SAMPLES_PER_DATA_BLOCK,num_channels); 

    #output number
    rhd.nums[:]=1;

    nothing 
end
