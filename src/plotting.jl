



#=
Plots detected spike on canvas for multiple channels
=#

function draw_spike16(rhd::RHD2000,han::Gui_Handles,ctx::Cairo.CairoContext)

    k=16*han.num16-15
    xbounds=1.0:124.0:375.0
    ybounds=75.0:125.0:450.0

    maxid=1
    increment=div(125,han.wave_points)*2

    #first ID
    @inbounds for i in xbounds
        for j in ybounds
            if han.enabled[k]
                for g=1:rhd.nums[k] #plotting every spike, do we need to do that?
                    if rhd.buf[g,k].inds.start>0
                        if rhd.buf[g,k].id==1
                            s=han.scale[k,2]
                            o=han.offset[k,2]
                            y=rhd.v[rhd.buf[g,k].inds.start,k]*s+j-o
                            move_to(ctx,1+i,y)
                            count=increment+1
                            for kk=rhd.buf[g,k].inds.start+2:2:rhd.buf[g,k].inds.stop
                                y=rhd.v[kk,k]*s+j-o
                                if y<j-65
                                    y=j-65.0
                                elseif y>j+65.0
                                    y=j+65.0
                                end  
                                line_to(ctx,count+i,y)
                                count+=increment
                            end
                        elseif rhd.buf[g,k].id>maxid
                            maxid=rhd.buf[g,k].id
                        end
                    end        
                end
            end
            k+=1
        end
    end
    
    set_line_width(ctx,0.5);
    @inbounds select_color(ctx,1)
    stroke(ctx)

    #subsequent IDs
    @inbounds for thisid=2:maxid
        k=16*han.num16-15
        
        for i in xbounds
            for j in ybounds
                if han.enabled[k]
                    for g=1:rhd.nums[k]
                        if rhd.buf[g,k].inds.start>0
                            if rhd.buf[g,k].id==thisid
                                s=han.scale[k,2]
                                o=han.offset[k,2]
                                move_to(ctx,1+i,rhd.v[rhd.buf[g,k].inds.start,k]*s+j-o)
                                count=increment+1
                                for kk=rhd.buf[g,k].inds.start+2:2:rhd.buf[g,k].inds.stop
                                    y=rhd.v[kk,k]*s+j-o
                                    if y<j-65.0
                                        y=j-65.0
                                    elseif y>j+65.0
                                        y=j+65.0
                                    end  
                                    line_to(ctx,count+i,y)
                                    count+=increment
                                end
                            end
                        end        
                    end
                end
                k+=1
            end
        end
        set_line_width(ctx,0.5);
        @inbounds select_color(ctx,thisid)
        stroke(ctx)
    end

    nothing
end

#=
Single maximized channel plotting
=#

function draw_spike(rhd::RHD2000,han::Gui_Handles,ctx::Cairo.CairoContext)

    spike_num=han.spike
    s=han.scale[han.spike,1]
    o=han.offset[han.spike,1]
    reads=han.draws

    increment=div(500,han.wave_points)
    
    for i=1:rhd.nums[spike_num]

        if rhd.buf[i,spike_num].inds.start>0
        
            @inbounds move_to(ctx,1,rhd.v[rhd.buf[i,spike_num].inds.start,spike_num]*s+300-o)
            
            #draw line
            count=increment+1
            @inbounds for k=rhd.buf[i,spike_num].inds.start+1:rhd.buf[i,spike_num].inds.stop
                y=rhd.v[k,spike_num]*s+300-o
                if y<1.0
                    y=1.0
                elseif y>600.0
                    y=600.0
                end
                @inbounds line_to(ctx,count,y)
                count+=increment
            end
			
	    count=(rhd.buf[i,spike_num].id-1)*100+10
	    @inbounds move_to(ctx,count,round(Int16,rhd.v[rhd.buf[i,spike_num].inds.start,spike_num]*.2*s+650-.2*o))
            
            #draw separted cluster
            count+=2
            @inbounds for k=rhd.buf[i,spike_num].inds.start+1:rhd.buf[i,spike_num].inds.stop
                @inbounds line_to(ctx,count,round(Int16,rhd.v[k,spike_num]*.2*s+650-.2*o))              
                count+=2
            end
			
	    @inbounds move_to(ctx,reads,(rhd.buf[i,spike_num].id-1)*20+700)
	    @inbounds line_to(ctx,reads,(rhd.buf[i,spike_num].id-1)*20+720)
			
	    set_line_width(ctx,0.5);
	    @inbounds select_color(ctx,rhd.buf[i,spike_num].id)
	    stroke(ctx)
        end
    end
   
    nothing
end

#=
Reset Canvas
=#

function clear_c(myc::Gtk.GtkCanvas,num16)
        
    ctx = getgc(myc)
    set_source_rgb(ctx,0.0,0.0,0.0)
    paint(ctx)

    for x in [125, 250, 375]
	move_to(ctx,x,1)
	line_to(ctx,x,500)
    end
    for y in [125,250,375,500,550,600,650,700,750]
	move_to(ctx,1,y)
	line_to(ctx,500,y)
    end
    set_source_rgb(ctx,1.0,1.0,1.0)
    stroke(ctx)

    k=16*num16-15
    for x in [10, 135, 260, 385]
        for y in [10, 135, 260, 385]
            move_to(ctx,x,y)
            show_text(ctx,string(k))
            k+=1
        end
    end
    
    nothing
end

function clear_c2(myc::Gtk.GtkCanvas,num)
        
    ctx = getgc(myc)

    set_source_rgb(ctx,0.0,0.0,0.0)
    paint(ctx)

    dashes = [10.0,  # ink 
          10.0,  # skip
          10.0,  # ink 
          10.0   # skip
              ];
    
    set_dash(ctx, dashes, 0.0)
    
    for y = [100, 200, 300, 400, 500]
        move_to(ctx,1,y)
        line_to(ctx,500,y)
    end

    for x = [100, 200, 300, 400]
        move_to(ctx,x,1)
        line_to(ctx,x,600)
    end

    set_source_rgba(ctx,1.0,1.0,1.0,.5)
    stroke(ctx) 
    
    set_dash(ctx,Float64[])
    
    move_to(ctx,1,600)
    line_to(ctx,500,600)
    set_source_rgb(ctx,1.0,1.0,1.0)
    stroke(ctx)

    move_to(ctx,10,10)
    show_text(ctx,string(num))
    
    nothing
end

function select_color(ctx,clus)

    if clus==1
        set_source_rgb(ctx,1.0,1.0,1.0) # white
    elseif clus==2
        set_source_rgb(ctx,1.0,1.0,0.0) #Yellow
    elseif clus==3
        set_source_rgb(ctx,0.0,1.0,0.0) #Green
    elseif clus==4
        set_source_rgb(ctx,0.0,0.0,1.0) #Blue
    elseif clus==5
        set_source_rgb(ctx,1.0,0.0,0.0) #Red
    else
        set_source_rgb(ctx,1.0,1.0,0.0)
    end
    
    nothing
end


