



#=
Plots detected spike on canvas for multiple channels
=#
function draw_spike(rhd::RHD2000,xoff::Int64,yoff::Int64,spike_num::Int64,ctx::Cairo.CairoContext,s::Float64,o::Float64)
    
    #first point
    
    for i=1:rhd.nums[spike_num]

        if rhd.buf[i,spike_num].inds[1]>0
    
            @inbounds move_to(ctx,1+xoff,(rhd.v[rhd.buf[i,spike_num].inds[1],spike_num]*s)+yoff-o);
            
            #draw line
            count=3
            @inbounds for k=rhd.buf[i,spike_num].inds[2]:rhd.buf[i,spike_num].inds[end] 
                @inbounds line_to(ctx,count+xoff,rhd.v[k,spike_num]*s+yoff-o);
                set_line_width(ctx,0.5);
                @inbounds select_color(ctx,rhd.buf[i,spike_num].id)
                count+=2
            end

        end
    end
    nothing
end

#=
Single maximized channel plotting
=#

function draw_spike(rhd::RHD2000,spike_num::Int64,ctx::Cairo.CairoContext,s::Float64,o::Float64)

    for i=1:rhd.nums[spike_num]

        if rhd.buf[i,spike_num].inds[1]>0
        
            @inbounds move_to(ctx,51,(rhd.v[rhd.buf[i,spike_num].inds[1],spike_num])*s+400-o);
            
            #draw line
            count=1
            @inbounds for k=rhd.buf[i,spike_num].inds[2]:rhd.buf[i,spike_num].inds[end] 
                @inbounds line_to(ctx,count,(rhd.v[k,spike_num])*s+400-o);
                set_line_width(ctx,0.5);
                @inbounds select_color(ctx,rhd.buf[i,spike_num].id)
                count+=12
            end
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

	for x in [200, 400, 600]
		move_to(ctx,x,1)
		line_to(ctx,x,800)
	end
	for y in [200,400,600]
		move_to(ctx,1,y)
		line_to(ctx,800,y)
	end
	set_source_rgb(ctx,0,0,0)
	stroke(ctx)
	
    nothing
end

function clear_c2(myc::Gtk.GtkCanvas)
        
    ctx = getgc(myc)
    set_source_rgb(ctx,1,1,1)
    paint(ctx)
        
    nothing
end

function select_color(ctx,clus::Int64)

    if clus==1
        set_source_rgb(ctx,1,0,0)
    elseif clus==2
        set_source_rgb(ctx,0,1,0)
    elseif clus==3
        set_source_rgb(ctx,0,0,1)
    elseif clus==4
        set_source_rgb(ctx,1,0,1)
    elseif clus==5
        set_source_rgb(ctx,0,1,1)
    else
        set_source_rgb(ctx,1,1,0)
    end
    
    nothing
end


