
type Gui_Handles
    win::Gtk.GtkWindowLeaf
    run::Gtk.GtkToggleButtonLeaf
    cal::Gtk.GtkCheckButtonLeaf
    slider::Gtk.GtkScaleLeaf
    adj::Gtk.GtkAdjustmentLeaf
    slider2::Gtk.GtkScaleLeaf
    adj2::Gtk.GtkAdjustmentLeaf
    c::Gtk.GtkCanvasLeaf
    c2::Gtk.GtkCanvasLeaf
end

function makegui(mynums::AbstractArray{Int64,2},spikes::AbstractArray{Spike,2},ns::AbstractArray{Int64,1})
    
    #Button to run Intan
    button = @ToggleButton("Run") 

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
    c2_slider=@Scale(false, 1:16)
    
    
    adj2 = @Adjustment(c2_slider)
    setproperty!(adj2,:value,1)

    #Arrangement of stuff on GUI
    grid = @Grid()
    grid[1,1]=button
    grid[2,1]=cal
    grid[3,2]=c
    grid[3,3]=c_slider
    grid[2,2]=c2
    grid[2,3]=c2_slider
    win = @Window(grid, "Intan.jl GUI")
    showall(win)

    
    
    #Callback function definitions

    #Drawing
    function run_cb(widgetptr::Ptr,user_data::Tuple{Gui_Handles,AbstractArray{Int64,2},AbstractArray{Spike,2},AbstractArray{Int64,1}})

        widget = convert(ToggleButton, widgetptr) 
        
        @async if getproperty(widget,:active,Bool)==true
        
            #unpack tuple
            han, num, myspikes, mycounts = user_data
            
            #get context
            ctx = getgc(han.c)
            
            s_old=1
            s_new=1
            
            while getproperty(widget,:active,Bool)==true
                  
                
                
                
                #plot spikes
                 
                s_new=getproperty(han.adj,:value,Int64)
                
                if s_new != s_old
                    clear_c(han.c)
                end
                
                s_old=s_new
                
                if s_old>0
                    
                    k=16*s_old-15
                    for i=0:200:600
                        for j=0:200:600
                            draw_spike(num,i,j,k,ctx,myspikes,mycounts)
                            k+=1
                        end
                    end
    
                stroke(ctx);
                reveal(han.c);
                
                end
                
                sleep(1.0)
            
            end
            
        end
        
        nothing
    end
    
    #Create type with handles to everything
    handles=Gui_Handles(win,button,cal,c_slider,adj,c2_slider,adj2,c,c2)
    
    #Connect Callbacks to objects on GUI
    
    #Run button starts main loop
    id = signal_connect(run_cb, button, "clicked",Void,(),false,(handles,mynums,spikes,ns))   
          
    return handles
    
end
