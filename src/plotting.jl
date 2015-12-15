



#=
Plots detected spike on canvas for multiple channels
=#
function draw_spike{T,V}(rhd::RHD2000{T,V},xoff::Int64,yoff::Int64,spike_num::Int64,ctx::Cairo.CairoContext)
    
    #first point
    
    for i=1:rhd.nums[spike_num]
    
        @inbounds move_to(ctx,1+xoff,rhd.v[rhd.buf[i,spike_num].inds[1],spike_num]+yoff);
            
        #draw line
        count=3
        @inbounds for k=rhd.buf[i,spike_num].inds[2]:rhd.buf[i,spike_num].inds[end] 
            @inbounds line_to(ctx,count+xoff,rhd.v[k,spike_num]+yoff);
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

function draw_spike{T,V}(rhd::RHD2000{T,V},spike_num::Int64,ctx::Cairo.CairoContext)

    for i=1:rhd.nums[spike_num]
    
        @inbounds move_to(ctx,51,rhd.v[rhd.buf[i,spike_num].inds[1],spike_num]+400);
            
        #draw line
        count=63
        @inbounds for k=rhd.buf[i,spike_num].inds[2]:rhd.buf[i,spike_num].inds[end] 
            @inbounds line_to(ctx,count,rhd.v[k,spike_num]+400);
            set_line_width(ctx,0.5);
            set_source_rgb(ctx, 1, 0, 0)
            count+=12
        end
    end
   
    nothing
end

#=
Reset Canvas
=#

function clear_c(myc::Gtk.GtkCanvas)
        
    ctx = getgc(myc)
    set_source_rgb(ctx,1,1,1)
    paint(ctx)
        
    nothing
end
