

function makegui(mynums::AbstractArray{Int64,2},spikes::AbstractArray{Spike,2},ns::AbstractArray{Int64,1})
    
    #Button to run Intan
    button = @ToggleButton("Start")

    #Calibration
    cal = @CheckButton("Calibrate")
    setproperty!(cal,:active,true)

    #16 channels at a time can be visualized on the right side
    c=@Canvas(800,800) #16 channels
    
    #Which 16 channels can be selected with a slider
    c_slider = @Scale(false, 0:(div(length(ns)-1,16)+1))
    adj = @Adjustment(c_slider)
    setproperty!(adj,:value,1)
    
    #One channel can be magnified for easier inspection
    c2=@Canvas(800,800) #Single channel to focus on

    
    #Arrangement of stuff on GUI
    grid = @Grid()
    grid[1,1]=button
    grid[2,1]=cal
    grid[3,2]=c
    grid[3,3]=c_slider
    grid[2,2]=c2
    win = @Window(grid, "Intan.jl GUI")
    showall(win)


    #Callback function definitions

    #Drawing
    function draw_cb(widgetptr::Ptr,user_data::Tuple{Gtk.GtkCanvas,AbstractArray{Int64,2},AbstractArray{Spike,2},AbstractArray{Int64,1}})

        #unpack tuple
        can, num, myspikes, mycounts = user_data
    
        #get context
        ctx = getgc(can)
        count=1
        
        for i=0:200:600
            for j=0:200:600
    
                draw_spike(num,i,j,count,ctx,myspikes,mycounts)
                count+=1
            end
        end
    
        stroke(ctx);
        reveal(can);
        
        nothing
    end
    
    #Connect Callbacks to objects on GUI
    signal_connect(draw_cb, button, "clicked",Void,(),false,(c,mynums,spikes,ns))
    
    return win,c
    
end
