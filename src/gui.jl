
type Gui_Handles
    win::Gtk.GtkWindowLeaf
    run::Gtk.GtkToggleButtonLeaf
    init::Gtk.GtkButtonLeaf
    cal::Gtk.GtkCheckButtonLeaf
    slider::Gtk.GtkScaleLeaf
    adj::Gtk.GtkAdjustmentLeaf
    slider2::Gtk.GtkScaleLeaf
    adj2::Gtk.GtkAdjustmentLeaf
    c::Gtk.GtkCanvasLeaf
    c2::Gtk.GtkCanvasLeaf
    slider3::Gtk.GtkScaleLeaf
    adj3::Gtk.GtkAdjustmentLeaf
    spike::Int64 #currently selected spike out of total
    num::Int64 #currently selected spike out of 16
    num16::Int64 #currently selected 16 channels
    scale::Array{Float64,2}
    offset::Array{Float64,2}
end

function makegui{T,U,V,W,X}(r::RHD2000{T,U,V,W,X})
    
    #Button to run Intan
    button = @ToggleButton("Run")

    #Button to initialize Board
    button_init = @Button("Init")

    #Calibration
    cal = @CheckButton("Calibrate")
    setproperty!(cal,:active,true)

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
    push!(hbox,button)
    push!(hbox,cal)
    grid[3,2]=c
    grid[3,3]=c_slider
    grid[2,2]=c2
    grid[2,3]=c2_slider
    setproperty!(grid, :column_spacing, 15) 
    setproperty!(grid, :row_spacing, 15) 
    win = @Window(grid, "Intan.jl GUI")
    showall(win)

    
    
    #Callback function definitions

    #Drawing
    function run_cb(widgetptr::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

        widget = convert(ToggleButton, widgetptr) 
        
        @async if getproperty(widget,:active,Bool)==true
        
            #unpack tuple
            han, rhd = user_data
            
            #get context
            ctx = getgc(han.c)
            ctx2 = getgc(han.c2)
            
            while getproperty(widget,:active,Bool)==true

                #get spikes and sort
                readDataBlocks(rhd,1)

                #process (e.g. kalman, spike triggered stim calc, etc)

                #output (e.g. cursor, stim, etc)

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
                    
                sleep(0.2)

                #write to disk
            
            end
            
        end
        
        nothing
    end


    function update_scale(widgetptr::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

        han, rhd = user_data

        @inbounds han.scale[han.spike,1]=getproperty(han.adj3,:value,Float64)
        @inbounds han.scale[han.spike,2]=han.scale[han.spike,1]*.25

        @inbounds han.offset[han.spike,1]=mean(han.scale[han.spike,1].*rhd.v[:,han.spike])
        @inbounds han.offset[han.spike,2]=mean(han.scale[han.spike,2].*rhd.v[:,han.spike])

        clear_c(han.c2)
        
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
            setproperty!(han.adj3,:value,han.scale[han.spike])
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
            setproperty!(han.adj3,:value,han.scale[han.spike])
        end
        
        nothing
    end

    function init_cb(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

        han, rhd = user_data
        
        init_board!(rhd)

        nothing
    end
    
 
    scales=ones(Float64,size(r.v,2),2)
    scales[:,2]=scales[:,2].*.25
    offs=zeros(Float64,size(r.v,2),2)
    offs[:,1]=squeeze(mean(r.v,1),1)
    offs[:,2]=offs[:,1]*.25

    #Create type with handles to everything
    handles=Gui_Handles(win,button,button_init,cal,c_slider,adj,c2_slider,adj2,c,c2,s_slider,adj3,1,1,1,scales,offs)
    
    #Connect Callbacks to objects on GUI
    
    #Run button starts main loop
    id = signal_connect(run_cb, button, "clicked",Void,(),false,(handles,r))

    id = signal_connect(update_c1, c_slider, "value-changed", Void, (), false, (handles,))

    id = signal_connect(update_c2, c2_slider, "value-changed", Void, (), false, (handles,))

    id = signal_connect(update_scale, s_slider, "value-changed", Void, (), false, (handles,r))

    id = signal_connect(init_cb, button_init, "clicked", Void, (), false, (handles,r))
          
    return handles
    
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
