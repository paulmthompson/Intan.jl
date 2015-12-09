



#=
Plots detected spike on canvas for multiple channels
=#
function draw_spike(data::AbstractArray{Int64,2},xoff::Int64,yoff::Int64,spike_num::Int64,ctx::Cairo.CairoContext,spikes::AbstractArray{Spike,2},ns::AbstractArray{Int64,1})
    
    #first point
    
    for i=1:ns[spike_num]
    
        @inbounds move_to(ctx,1+xoff,data[spikes[i,spike_num].inds[1],spike_num]+yoff);
            
        #draw line
        count=3
        @inbounds for k=spikes[i,spike_num].inds[2]:spikes[i,spike_num].inds[end] 
            @inbounds line_to(ctx,count+xoff,data[k,spike_num]+yoff);
            set_line_width(ctx,0.5);
            set_source_rgb(ctx, 1, 0, 0)
            count+=2
        end
    end
    nothing
end

#=
Single maximized channel plotting
=#

#=
Reset Canvas
=#

function clear_c(myc::Gtk.GtkCanvas)
        
    ctx = getgc(myc)
    set_source_rgb(ctx,1.0,1.0,1.0)
    rectangle(ctx, 0,0,800,800)
    paint(ctx)
        
    nothing
end
