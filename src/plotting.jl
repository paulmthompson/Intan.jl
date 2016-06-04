



#=
Plots detected spike on canvas for multiple channels
=#

function draw_spike16(rhd::RHD2000,han::Gui_Handles,ctx::Cairo.CairoContext)

    k=16*han.num16-15
    xbounds=1:124:375
    ybounds=75:125:450

    maxid=1

    #first ID
    @inbounds for i in xbounds
        for j in ybounds
            for g=1:rhd.nums[k]
                if rhd.buf[g,k].inds[1]>0
                    if rhd.buf[g,k].id==1
                        s=han.scale[k,2]
                        o=han.offset[k,2]
                        move_to(ctx,1+i,round(Int16,rhd.v[rhd.buf[g,k].inds[1],k]*s+j-o))
                        count=3
                        for kk=rhd.buf[g,k].inds[2]:rhd.buf[g,k].inds[end] 
                            line_to(ctx,count+i,round(Int16,rhd.v[kk,k]*s+j-o))
                            count+=2
                        end
                    elseif rhd.buf[g,k].id>maxid
                        maxid=rhd.buf[g,k].id
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
                for g=1:rhd.nums[k]
                    if rhd.buf[g,k].inds[1]>0
                        if rhd.buf[g,k].id==thisid
                            s=han.scale[k,2]
                            o=han.offset[k,2]
                            move_to(ctx,1+i,round(Int16,rhd.v[rhd.buf[g,k].inds[1],k]*s+j-o))
                            count=3
                            for kk=rhd.buf[g,k].inds[2]:rhd.buf[g,k].inds[end] 
                                line_to(ctx,count+i,round(Int16,rhd.v[kk,k]*s+j-o))
                                count+=2
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

function draw_spike(rhd::RHD2000,spike_num::Int64,ctx::Cairo.CairoContext,s::Float64,o::Float64,reads::Int64)

    for i=1:rhd.nums[spike_num]

        if rhd.buf[i,spike_num].inds[1]>0
        
            @inbounds move_to(ctx,1,round(Int16,rhd.v[rhd.buf[i,spike_num].inds[1],spike_num]*s+300-o))
            
            #draw line
            count=11
            @inbounds for k=rhd.buf[i,spike_num].inds[2]:rhd.buf[i,spike_num].inds[end] 
                @inbounds line_to(ctx,count,round(Int16,rhd.v[k,spike_num]*s+300-o))
                count+=10
            end
			
	    count=(rhd.buf[i,spike_num].id-1)*100+10
	    @inbounds move_to(ctx,count,round(Int16,rhd.v[rhd.buf[i,spike_num].inds[1],spike_num]*.2*s+650-.2*o))
            
            #draw separted cluster
            count+=2
            @inbounds for k=rhd.buf[i,spike_num].inds[2]:rhd.buf[i,spike_num].inds[end] 
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
    set_source_rgb(ctx,1,1,1)
    paint(ctx)

    for x in [125, 250, 375]
	move_to(ctx,x,1)
	line_to(ctx,x,500)
    end
    for y in [125,250,375,500,550,600,650,700,750]
	move_to(ctx,1,y)
	line_to(ctx,500,y)
    end
    set_source_rgb(ctx,0,0,0)
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
    set_source_rgb(ctx,1,1,1)
    paint(ctx)
	
    move_to(ctx,1,600)
    line_to(ctx,500,600)
    set_source_rgb(ctx,0,0,0)
    stroke(ctx)

    move_to(ctx,10,10)
    show_text(ctx,string(num))
    
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


