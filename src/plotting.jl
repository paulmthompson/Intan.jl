



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
                            o=han.offset[k]
                            y=(rhd.v[rhd.buf[g,k].inds.start,k]-o)*s+j
                            move_to(ctx,1+i,y)
                            count=increment+1
                            for kk=rhd.buf[g,k].inds.start+2:2:rhd.buf[g,k].inds.stop
                                y=(rhd.v[kk,k]-o)*s+j
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
                                o=han.offset[k]
                                move_to(ctx,1+i,(rhd.v[rhd.buf[g,k].inds.start,k]-o)*s+j)
                                count=increment+1
                                for kk=rhd.buf[g,k].inds.start+2:2:rhd.buf[g,k].inds.stop
                                    y=(rhd.v[kk,k]-o)*s+j
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

function draw_spike32(rhd::RHD2000,han::Gui_Handles,ctx::Cairo.CairoContext)

    k=32*div(han.num16+1,2)-31
    xbounds=1.0:83.0:416.0
    ybounds=41.0:83.0:456.0

    maxid=1
    increment=div(83,han.wave_points)*2

    #first ID
    @inbounds for i in xbounds
        for j in ybounds
            if han.enabled[k]
                for g=1:rhd.nums[k] #plotting every spike, do we need to do that?
                    if rhd.buf[g,k].inds.start>0
                        if rhd.buf[g,k].id==1
                            s=han.scale[k,1]/6
                            o=han.offset[k]
                            y=(rhd.v[rhd.buf[g,k].inds.start,k]-o)*s+j
                            move_to(ctx,1+i,y)
                            count=increment+1
                            for kk=rhd.buf[g,k].inds.start+2:2:rhd.buf[g,k].inds.stop
                                y=(rhd.v[kk,k]-o)*s+j
                                if y<j-40.0
                                    y=j-40.0
                                elseif y>j+40.0
                                    y=j+40.0
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
        k=32*div(han.num16+1,2)-31
        
        for i in xbounds
            for j in ybounds
                if han.enabled[k]
                    for g=1:rhd.nums[k]
                        if rhd.buf[g,k].inds.start>0
                            if rhd.buf[g,k].id==thisid
                                s=han.scale[k,1]/6
                                o=han.offset[k]
                                move_to(ctx,1+i,(rhd.v[rhd.buf[g,k].inds.start,k]-o)*s+j)
                                count=increment+1
                                for kk=rhd.buf[g,k].inds.start+2:2:rhd.buf[g,k].inds.stop
                                    y=(rhd.v[kk,k]-o)*s+j
                                    if y<j-40.0
                                        y=j-40.0
                                    elseif y>j+40.0
                                        y=j+40.0
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

function draw_raster16(rhd::RHD2000,han::Gui_Handles,ctx::Cairo.CairoContext)

    k=16*han.num16-15

    maxid=1

    #first ID
    count=1
    for i=k:(k+15)
        if han.enabled[i]
            for g=1:rhd.nums[i] #plotting every spike, do we need to do that?  
                if rhd.buf[g,i].id==1
                    offset=500.0+18.0*(count-1)
                    move_to(ctx,han.draws,offset)
                    line_to(ctx,han.draws,offset+15.0)
                elseif rhd.buf[g,i].id>maxid
                    maxid=rhd.buf[g,i].id
                end    
            end
        end
        count+=1
    end
    
    set_line_width(ctx,0.5);
    @inbounds select_color(ctx,1)
    stroke(ctx)

    #subsequent IDs
    @inbounds for thisid=2:maxid
        k=16*han.num16-15
        count=1
        for i=k:(k+15)
            if han.enabled[i]
                for g=1:rhd.nums[i] #plotting every spike, do we need to do that?  
                    if rhd.buf[g,i].id==thisid
                        offset=500.0+18.0*(count-1)
                        move_to(ctx,han.draws,offset)
                        line_to(ctx,han.draws,offset+15.0)
                    end    
                end
            end
            count+=1
        end
    
        set_line_width(ctx,0.5);
        @inbounds select_color(ctx,thisid)
        stroke(ctx)
    end

    nothing
    
end

function draw_raster32(rhd::RHD2000,han::Gui_Handles,ctx::Cairo.CairoContext)

    k=32*div(han.num16+1,2)-31

    maxid=1

    #first ID
    count=1
    for i=k:(k+31)
        if han.enabled[i]
            for g=1:rhd.nums[i] #plotting every spike, do we need to do that?  
                if rhd.buf[g,i].id==1
                    offset=500.0+9.0*(count-1)
                    move_to(ctx,han.draws,offset)
                    line_to(ctx,han.draws,offset+6.0)
                elseif rhd.buf[g,i].id>maxid
                    maxid=rhd.buf[g,i].id
                end    
            end
        end
        count+=1
    end
    
    set_line_width(ctx,0.5);
    @inbounds select_color(ctx,1)
    stroke(ctx)

    #subsequent IDs
    @inbounds for thisid=2:maxid
        k=32*div(han.num16+1,2)-31
        count=1
        for i=k:(k+31)
            if han.enabled[i]
                for g=1:rhd.nums[i] #plotting every spike, do we need to do that?  
                    if rhd.buf[g,i].id==thisid
                        offset=500.0+9.0*(count-1)
                        move_to(ctx,han.draws,offset)
                        line_to(ctx,han.draws,offset+6.0)
                    end    
                end
            end
            count+=1
        end
    
        set_line_width(ctx,0.5);
        @inbounds select_color(ctx,thisid)
        stroke(ctx)
    end

    nothing
    
end

function draw_raster64(rhd::RHD2000,han::Gui_Handles,ctx::Cairo.CairoContext)

    k=64*div(han.num16+3,4)-63

    maxid=1

    #first ID
    count=1
    for i=k:(k+63)
        if han.enabled[i]
            for g=1:rhd.nums[i] #plotting every spike, do we need to do that?  
                if rhd.buf[g,i].id==1
                    offset=12.0*(count-1)
                    move_to(ctx,han.draws,offset)
                    line_to(ctx,han.draws,offset+10.0)
                elseif rhd.buf[g,i].id>maxid
                    maxid=rhd.buf[g,i].id
                end    
            end
        end
        count+=1
    end
    
    set_line_width(ctx,0.5);
    @inbounds select_color(ctx,1)
    stroke(ctx)

    #subsequent IDs
    @inbounds for thisid=2:maxid
        k=64*div(han.num16+3,4)-63
        count=1
        for i=k:(k+63)
            if han.enabled[i]
                for g=1:rhd.nums[i] #plotting every spike, do we need to do that?  
                    if rhd.buf[g,i].id==thisid
                        offset=12.0*(count-1)
                        move_to(ctx,han.draws,offset)
                        line_to(ctx,han.draws,offset+10.0)
                    end    
                end
            end
            count+=1
        end
    
        set_line_width(ctx,0.5);
        @inbounds select_color(ctx,thisid)
        stroke(ctx)
    end

    
    nothing
end

function draw_scope(rhd::RHD2000,han::Gui_Handles,ctx::Cairo.CairoContext)

    #Paint over old line
    move_to(ctx,1.0,han.scope[1])
    for i=2:499
        line_to(ctx,i,han.scope[i,1])
    end
    set_source_rgb(ctx,0.0,0.0,0.0)
    set_line_width(ctx,2.0)
    stroke(ctx)
   
    s=han.scale[han.spike,2]

    #Draw voltage trace from desired channel
    move_to(ctx,1.0,550.0+rhd.v[1,han.spike]*s)
    han.scope[1]=550.0+rhd.v[1,han.spike]*s
    scope_ind=2
    count=2.0
    for i=3:2:600
        y=550.0+rhd.v[i,han.spike]*s
        line_to(ctx,count,y)
        han.scope[scope_ind,1]=y
        scope_ind+=1
        count+=1.0
    end
    set_source_rgb(ctx,1.0,1.0,1.0)
    set_line_width(ctx,0.5)
    stroke(ctx)

    nothing
end

#Event plotting

function plot_events(rhd::RHD2000,han::Gui_Handles,myreads::Int64)

    @inbounds for i=1:6
	if han.events[i]>-1
	    if han.events[i]<8 #analog
		val=parse_analog(rhd,han,han.events[i]+1)
		plot_analog(rhd,han,i,myreads,val)
	    else
		val=parse_ttl(rhd,han,han.events[i]-7)
		plot_ttl(rhd,han,i,myreads,val)
	    end
	end
    end

    nothing
end

function parse_analog(rhd::RHD2000,han::Gui_Handles,chan::Int64)

    mysum=0
    for i=1:size(rhd.fpga[1].adc,1)
	mysum+=rhd.fpga[1].adc[i,chan]
    end
    
    round(Int64,mysum/size(rhd.fpga[1].adc,1)/0xffff*30)
end

function plot_analog(rhd::RHD2000,han::Gui_Handles,channel::Int64,myreads::Int64,val::Int64)

    ctx=getgc(han.c)
    
    move_to(ctx,myreads-1,540+(channel-1)*50-val)
    line_to(ctx,myreads,540+(channel-1)*50-val)
    set_source_rgb(ctx,1.0,1.0,0.0)
    stroke(ctx)
    
    nothing
end

function parse_ttl(rhd::RHD2000,han::Gui_Handles,chan::Int64)
   
    y=0
    
    for i=1:length(rhd.fpga[1].ttlin)
        y=y|(rhd.fpga[1].ttlin[i]&(2^(chan-1)))
    end
    
    if y>0
        return true
    else
        return false
    end
end

function plot_ttl(rhd::RHD2000,han::Gui_Handles,channel::Int64,myreads::Int64,val::Bool)

    ctx=getgc(han.c)

    offset=0
    if val==true
	offset=30
    end
    
    move_to(ctx,myreads-1,540+(channel-1)*50-offset)
    line_to(ctx,myreads,540+(channel-1)*50-offset)
    set_source_rgb(ctx,1.0,1.0,0.0)
    stroke(ctx)
    
    nothing
end


#=
Single maximized channel plotting
=#

function draw_spike(rhd::RHD2000,han::Gui_Handles,ctx::Cairo.CairoContext)

    spike_num=han.spike
    s=han.scale[han.spike,1]
    o=han.offset[han.spike]
    reads=han.draws

    increment=div(500,han.wave_points)
    
    for i=1:rhd.nums[spike_num]

        if rhd.buf[i,spike_num].inds.start>0
        
            @inbounds move_to(ctx,1,(rhd.v[rhd.buf[i,spike_num].inds.start,spike_num]-o)*s+300)
            
            #draw line
            count=increment+1
            @inbounds for k=rhd.buf[i,spike_num].inds.start+1:rhd.buf[i,spike_num].inds.stop
                y=(rhd.v[k,spike_num]-o)*s+300
                if y<1.0
                    y=1.0
                elseif y>600.0
                    y=600.0
                end
                @inbounds line_to(ctx,count,y)
                count+=increment
            end
			
	    count=(rhd.buf[i,spike_num].id-1)*100+10
	    @inbounds move_to(ctx,count,round(Int16,(rhd.v[rhd.buf[i,spike_num].inds.start,spike_num]-o)*.2*s+650))
            
            #draw separted cluster
            count+=2
            @inbounds for k=rhd.buf[i,spike_num].inds.start+1:rhd.buf[i,spike_num].inds.stop
                @inbounds line_to(ctx,count,(rhd.v[k,spike_num]-o)*.2*s+650)              
                count+=2
            end
			
	    @inbounds move_to(ctx,reads,(rhd.buf[i,spike_num].id-1)*20.0+700.0)
	    @inbounds line_to(ctx,reads,(rhd.buf[i,spike_num].id-1)*20.0+720.0)
			
	    set_line_width(ctx,0.5);
	    @inbounds select_color(ctx,rhd.buf[i,spike_num].id)
	    stroke(ctx)

            if han.buf_count > 0
                mycount=1
                for tt in rhd.buf[i,spike_num].inds
                    han.spike_buf[mycount,han.buf_ind]=rhd.v[tt,spike_num]
                    mycount+=1
                end
                han.buf_count+=1
                han.buf_ind+=1
                if han.buf_count>500
                    han.buf_count=500
                end
                if han.buf_ind>500
                    han.buf_ind=1
                end
            end
        end
    end
   
    nothing
end

#=
Reset Canvas
=#

function clear_c(han::Gui_Handles)

    #paint it black
    ctx = getgc(han.c)
    set_source_rgb(ctx,0.0,0.0,0.0)
    paint(ctx)

    if han.c_right_top==1
        prepare_16(ctx,han)
    elseif han.c_right_top==2
        prepare_32(ctx,han)
    elseif han.c_right_top==3
        prepare_64(ctx,han)
    else
    end

    if han.c_right_bottom==1
        prepare_events(ctx,han)
    elseif han.c_right_bottom==2
    elseif han.c_right_bottom==3
    elseif han.c_right_bottom==4
        prepare_scope(ctx,han)
    elseif han.c_right_bottom==5
    else
        
    end
    nothing
end

function prepare_16(ctx::Cairo.CairoContext,han::Gui_Handles)

    for x in [125, 250, 375]
	move_to(ctx,x,1)
	line_to(ctx,x,500)
    end
    for y in [125,250,375,500]
	move_to(ctx,1,y)
	line_to(ctx,500,y)
    end
    set_source_rgb(ctx,1.0,1.0,1.0)
    set_line_width(ctx,1.0)
    stroke(ctx)

    k=16*han.num16-15
    for x in [10, 135, 260, 385]
        for y in [10, 135, 260, 385]
            if k<=length(han.enabled)
                move_to(ctx,x,y)
                if han.enabled[k] 
                    show_text(ctx,string(k))
                else
                    show_text(ctx,string(k,"-DISABLED"))
                end
            end
            k+=1
        end
    end

    nothing
end

function prepare_32(ctx::Cairo.CairoContext,han::Gui_Handles)

    for x in collect(84.0:83.0:450.0)
	move_to(ctx,x,1)
	line_to(ctx,x,500.0)
    end
    for y in collect(84.0:83.0:499.0)
	move_to(ctx,1.0,y)
	line_to(ctx,500.0,y)
    end
    set_source_rgb(ctx,1.0,1.0,1.0)
    set_line_width(ctx,1.0)
    stroke(ctx)

    k=32*div(han.num16+1,2)-31
    for x in collect(10.0:83.0:450.0)
        for y in collect(10.0:83.0:450.0)
            if k<=length(han.enabled)
                move_to(ctx,x,y)
                if han.enabled[k]
                    show_text(ctx,string(k))
                else
                    show_text(ctx,string(k,"-DISABLED"))
                end
            end
            k+=1
        end
    end

    nothing
end

function prepare_64(ctx::Cairo.CairoContext,han::Gui_Handles)
    
    for x in collect(35.0:72.0:467.0)
	move_to(ctx,x,1)
	line_to(ctx,x,793.0)
    end
    for y in collect(73.0:72.0:793.0)
	move_to(ctx,35.0,y)
	line_to(ctx,467.0,y)
    end
    set_source_rgb(ctx,1.0,1.0,1.0)
    set_line_width(ctx,1.0)
    stroke(ctx)

    k=64*div(han.num16+3,4)-63
    for x in collect(45.0:72.0:405.0)
        for y in collect(10.0:72.0:731.0)
            move_to(ctx,x,y)
            if k<=length(han.enabled)
                if han.enabled[k]
                    show_text(ctx,string(k))
                else
                    show_text(ctx,string(k,"-DISABLED"))
                end
            end
            k+=1
        end
    end

    nothing
end

function prepare_raster16(ctx)
end

function prepare_raster32(ctx)
end

function prepare_events(ctx,han)

    for y in collect(550.0:50.0:750.0)
	move_to(ctx,1.0,y)
	line_to(ctx,500.0,y)
    end
    set_source_rgb(ctx,1.0,1.0,1.0)
    set_line_width(ctx,1.0)
    stroke(ctx)

    for i=1:6
	if han.events[i]>-1
            move_to(ctx,10,460+i*50)
	    if han.events[i]<8 #analog
		show_text(ctx,string("A",han.events[i]))
	    else
		show_text(ctx,string("TTL",han.events[i]-8))
	    end
	end
    end
    
    nothing
end

function prepare_scope(ctx,han)

    for y in [600, 700]
	move_to(ctx,1.0,y)
	line_to(ctx,500.0,y)
    end

    set_source_rgb(ctx,1.0,1.0,1.0)
    set_line_width(ctx,1.0)
    stroke(ctx)

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

function plot_new_color(ctx::Cairo.CairoContext,han::Intan.Gui_Handles,clus::Int64)

    increment=div(500,han.wave_points)
    s=han.scale[han.spike,1]
    o=han.offset[han.spike]
    
    Intan.select_color(ctx,clus+1)
    
    for i=1:han.buf_count

        if han.buf_clus[i]==clus
            move_to(ctx,1,(han.spike_buf[1,i]-o)*s+300)
            count=increment+1
            for j=2:size(han.spike_buf,1)
                line_to(ctx,count,(han.spike_buf[j,i]-o)*s+300)
                count+=increment
            end
        end
    end
    stroke(ctx)
    reveal(han.c2)

    nothing
end

#Finds all spikes in buffer that are selected by windows
function window_cluster(han::Gui_Handles,clus::Int64)

    for i=1:han.buf_count

        hits=0
        for j=1:length(han.spike_win) #Loop over all windows
            a1=han.spike_win[j].x1
            a2=han.spike_win[j].x2
            b1=han.spike_win[j].y1
            b2=han.spike_win[j].y2
            for k=(han.spike_win[j].x1-1):(han.spike_win[j].x2+1)
                if SpikeSorting.intersect(a1,a2,k,k+1,b1,b2,han.spike_buf[k,i],han.spike_buf[k+1,i])
                    hits+=1
                    break
                end
            end
        end
        if hits==length(han.spike_win)
            han.buf_clus[i]=clus
        end
    end

    nothing
end
