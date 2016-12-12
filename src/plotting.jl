#=
Plots detected spike on canvas for multiple channels
=#

function draw_spike16(rhd::RHD2000,han::Gui_Handles,ctx::Cairo.CairoContext)

    k=16*han.num16-15
    xbounds=1.0:124.0:375.0
    ybounds=75.0:125.0:450.0
    increment=div(125,han.wave_points)*2

    draw_spike_n(rhd,han,ctx,k,xbounds,ybounds,increment,65.0)
    nothing
end

function draw_spike32(rhd::RHD2000,han::Gui_Handles,ctx::Cairo.CairoContext)
    
    k=32*div(han.num16+1,2)-31
    xbounds=1.0:83.0:416.0
    ybounds=41.0:83.0:456.0

    increment=div(83,han.wave_points)*2

    draw_spike_n(rhd,han,ctx,k,xbounds,ybounds,increment,40.0)
    nothing
end

function draw_spike_n(rhd::RHD2000,han::Gui_Handles,ctx::Cairo.CairoContext,k_in,xbounds,ybounds,increment,b_width)

    maxid=find_max_id(rhd,han,ctx,k_in,length(xbounds)*length(ybounds))

    #subsequent IDs
    @inbounds for thisid=1:maxid
        k=k_in
        for i in xbounds, j in ybounds
            if han.enabled[k]
                for g=1:rhd.nums[k]
                    if (rhd.buf[g,k].inds.start>0)&(rhd.buf[g,k].inds.stop<size(rhd.v,1))
                        if rhd.buf[g,k].id==thisid
                            s=han.scale[k,2]
                            o=han.offset[k]
                            move_to(ctx,1+i,(rhd.v[rhd.buf[g,k].inds.start,k]-o)*s+j)
                            count=increment+1
                            for kk=rhd.buf[g,k].inds.start+2:2:rhd.buf[g,k].inds.stop
                                y=(rhd.v[kk,k]-o)*s+j
                                if y<j-b_width
                                    y=j-b_width
                                elseif y>j+b_width
                                    y=j+b_width
                                end  
                                line_to(ctx,count+i,y)
                                count+=increment
                            end
                        end
                    end        
                end
            end
            k+=1
            if k>length(han.enabled)
                break
            end
        end
        set_line_width(ctx,0.5);
        @inbounds select_color(ctx,thisid)
        stroke(ctx)
    end

    nothing
end

function find_max_id(rhd::RHD2000,han::Gui_Handles,ctx::Cairo.CairoContext,k,num)

    maxid=1
    
    for i=k:(k+num-1)
        if han.enabled[k]
            for g=1:rhd.nums[k]
                if rhd.buf[g,k].id>maxid
                    maxid=rhd.buf[g,k].id
                end
            end
        end
    end
    maxid
end

function draw_raster_n(rhd::RHD2000,han::Gui_Handles,ctx::Cairo.CairoContext,k,k_itr,ctx_step,myoff)

    maxid=find_max_id(rhd,han,ctx,k,k_itr+1)

    @inbounds for thisid=1:maxid
        count=1
        for i=k:(k+k_itr)
            if han.enabled[i]
                for g=1:rhd.nums[i] #plotting every spike, do we need to do that?  
                    if rhd.buf[g,i].id==thisid
                        offset=myoff+ctx_step*(count-1)
                        move_to(ctx,han.draws,offset)
                        line_to(ctx,han.draws,offset+ctx_step-3.0)
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

function draw_raster16(rhd::RHD2000,han::Gui_Handles,ctx::Cairo.CairoContext)
    draw_raster_n(rhd,han,ctx,16*han.num16-15,15,18.0,500.0)
end

function draw_raster32(rhd::RHD2000,han::Gui_Handles,ctx::Cairo.CairoContext)
    draw_raster_n(rhd,han,ctx,32*div(han.num16+1,2)-31,31,9.0,500.0)
end

function draw_raster64(rhd::RHD2000,han::Gui_Handles,ctx::Cairo.CairoContext)
    draw_raster_n(rhd,han,ctx,64*div(han.num16+3,4)-63,63,12.0,0.0)
end

function draw_scope(rhd::RHD2000,han::Gui_Handles,ctx::Cairo.CairoContext)

    if han.soft.draws>9

        startind=512*(han.soft.draws-1)+1
        for i=1:512
            han.soft.v[startind]=rhd.v[i,han.spike]
            startind+=1
        end
        
        #Paint over old line
        move_to(ctx,1.0,han.soft.last[1])
        for i=2:499
            line_to(ctx,i,han.soft.last[i])
        end
        set_source_rgb(ctx,0.0,0.0,0.0)
        set_line_width(ctx,2.0)
        stroke(ctx)
        
        s=han.soft.v_div
        
        #Draw voltage trace from desired channel
        move_to(ctx,1.0,650.0+han.soft.v[1]*s)
        han.soft.last[1]=650.0+han.soft.v[1]*s

        t_iter=round(Int64,han.soft.t_div)
        
        scope_ind=1+t_iter
        for i=2:512
            y=650.0+han.soft.v[scope_ind]*s
            line_to(ctx,i,y)
            han.soft.last[i]=y
            scope_ind+=t_iter
        end
        set_source_rgb(ctx,1.0,1.0,1.0)
        set_line_width(ctx,0.5)
        stroke(ctx)
        
        han.soft.draws=1
    else
        startind=512*(han.soft.draws-1)+1
        for i=1:512
            han.soft.v[startind]=rhd.v[i,han.spike]
            startind+=1
        end
        han.soft.draws+=1
    end

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

    Cairo.translate(ctx,0.0,300.0)
    scale(ctx,500/han.wave_points,s)
    
    for i=1:rhd.nums[spike_num]

        kk=rhd.buf[i,spike_num].inds.start
        k_end=rhd.buf[i,spike_num].inds.stop
        if (kk>0) & (k_end<size(rhd.v,1))
        
            move_to(ctx,1,rhd.v[kk,spike_num]-o)
            
            for k=2:han.wave_points
                y = rhd.v[kk+k-1,spike_num]-o
                line_to(ctx,k,y)
            end
			
	    set_line_width(ctx,0.5);
	    @inbounds select_color(ctx,rhd.buf[i,spike_num].id)
	    stroke(ctx)

            #Add spike to buffer
            if han.buf_count > 0
                mycount=1
                for k=1:han.wave_points
                    han.spike_buf[mycount,han.buf_ind] = rhd.v[kk+k-1,spike_num]
                    mycount+=1
                end
                han.buf_clus[han.buf_ind] = rhd.buf[i,spike_num].id-1
                han.buf_count+=1
                han.buf_ind+=1
                if han.buf_count>500
                    han.buf_count=500
                end
                if han.buf_ind>500
                    han.buf_ind=1
                end
            end

            update_isi(rhd,han,i)
        end
    end

    identity_matrix(ctx)
    
    nothing
end

identity_matrix(ctx)=ccall((:cairo_identity_matrix,Cairo._jl_libcairo),Void, (Ptr{Void},), ctx.ptr)

function update_isi(rhd::RHD2000,han::Gui_Handles,i)

    spike_num=han.spike
    clus=rhd.buf[i,spike_num].id
    mytime=rhd.time[rhd.buf[i,spike_num].inds.start,1]

    my_isi = mytime - han.isi_last_time[clus]

    han.isi_last_time[clus] = mytime

    han.isi[han.isi_ind] = my_isi

    han.isi_clus_ID[han.isi_ind] = clus

    han.isi_ind+=1
    if han.isi_ind>500
        han.isi_ind=1
    end

    han.isi_count+=1
    if han.isi_count>500
        han.isi_count=500
    end
    
    nothing
end

function draw_isi(rhd::RHD2000,han::Gui_Handles)

    ctx=Cairo.getgc(han.c3)
    
    for i=1:han.total_clus[han.spike]        

        mycount=0
        myviolation=0
        for j=1:han.isi_count
            if han.isi_clus_ID[j] == i+1
                if han.isi[j]/rhd.sr < .0025
                   myviolation += 1
                end
                mycount+=1

                ind=1
                this_isi = han.isi[j]/rhd.sr
                for k=.001:.001:.049
                    if (this_isi > k - .001)&(this_isi < k)
                        han.isi_hist[ind]+=1
                    end
                    ind+=1
                end
            end
        end

        isi_f=round(myviolation/mycount*100,2)
        if isi_f>5.0
            set_source_rgb(ctx,1.0,0.0,0.0)
        else
            set_source_rgb(ctx,1.0,1.0,1.0)
        end
        move_to(ctx,(i-1)*100+1,10)
        show_text(ctx,string(isi_f))

        set_source_rgb(ctx,1.0,1.0,1.0)
        move_to(ctx,(i-1)*100+21,130)
        line_to(ctx,(i-1)*100+21,80)
        move_to(ctx,(i-1)*100+21,130)
        line_to(ctx,(i-1)*100+71,130)

        stroke(ctx)

        select_color(ctx,i+1)
        move_to(ctx,(i-1)*100+21,130)
        line_to(ctx,(i-1)*100+21,130-han.isi_hist[1]*6)
        han.isi_hist[1]=0

        for j=2:length(han.isi_hist)
            move_to(ctx,(i-1)*100+j+20,130)
            line_to(ctx,(i-1)*100+j+20,130-han.isi_hist[j]*6)
            han.isi_hist[j]=0
        end
        stroke(ctx)
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

function check16(mytest)
    count=1
    x1=1
    x2=1
    y1=1
    y2=1
    for x in [1, 125, 250, 375]
        for y in [1, 125, 250, 375]
            if count == (((mytest-1) % 16) + 1)
                x1 = x
                y1 = y
                x2 = x + 124
                y2 = y + 124
            end
            count += 1
        end            
    end
    (x1,x2,y1,y2)
end

function check32(mytest)
    count=1
    x1=1
    x2=1
    y1=1
    y2=1
    for x in collect(1:83:450)
        for y in collect(1:83:450)
            if count == (((mytest-1) % 32) + 1)
                x1 = x
                y1 = y
                x2 = x + 83
                y2 = y + 83
            end
            count += 1
        end            
    end
    (x1,x2,y1,y2)
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

    (x1_f,x2_f,y1_f,y2_f)=check16(han.spike)
    move_to(ctx,x1_f,y1_f)
    line_to(ctx,x2_f,y1_f)
    line_to(ctx,x2_f,y2_f)
    line_to(ctx,x1_f,y2_f)
    line_to(ctx,x1_f,y1_f)
    set_source_rgb(ctx,1.0,0.0,1.0)
    set_line_width(ctx,1.0)
    stroke(ctx)
    
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

    (x1_f,x2_f,y1_f,y2_f)=check32(han.spike)
    move_to(ctx,x1_f,y1_f)
    line_to(ctx,x2_f,y1_f)
    line_to(ctx,x2_f,y2_f)
    line_to(ctx,x1_f,y2_f)
    line_to(ctx,x1_f,y1_f)
    set_source_rgb(ctx,1.0,0.0,1.0)
    set_line_width(ctx,1.0)
    stroke(ctx)

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

    #=
    for y in [600, 700]
	move_to(ctx,1.0,y)
	line_to(ctx,500.0,y)
    end

    set_source_rgb(ctx,1.0,1.0,1.0)
    set_line_width(ctx,1.0)
    stroke(ctx)
    =#

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

    move_to(ctx,1,300)
    line_to(ctx,500,300)
    stroke(ctx)

    move_to(ctx,10,10)
    show_text(ctx,string(num))
    
    nothing
end

function clear_c3(c3,num)

    ctx = getgc(c3)

    set_source_rgb(ctx,0.0,0.0,0.0)
    paint(ctx)
    
    nothing
end

function select_color(ctx,clus,alpha=1.0)

    if clus==1
        set_source_rgba(ctx,1.0,1.0,1.0,alpha) # white
    elseif clus==2
        set_source_rgba(ctx,1.0,1.0,0.0,alpha) #Yellow
    elseif clus==3
        set_source_rgba(ctx,0.0,1.0,0.0,alpha) #Green
    elseif clus==4
        set_source_rgba(ctx,0.0,0.0,1.0,alpha) #Blue
    elseif clus==5
        set_source_rgba(ctx,1.0,0.0,0.0,alpha) #Red
    else
        set_source_rgba(ctx,1.0,1.0,0.0,alpha)
    end
    
    nothing
end

#Replots spikes assigned to specified cluster 
function plot_new_color(ctx::Cairo.CairoContext,han::Gui_Handles,clus::Int64)

    s=han.scale[han.spike,1]
    o=han.offset[han.spike]

    Cairo.translate(ctx,0.0,300.0)
    scale(ctx,500/han.wave_points,s)

    #Plot Noise
    select_color(ctx,1)
    @inbounds for i=1:han.buf_ind

        if han.buf_clus[i]==0
            move_to(ctx,1,(han.spike_buf[1,i]-o))
            for j=2:size(han.spike_buf,1)
                line_to(ctx,j,han.spike_buf[j,i]-o)
            end
        end
    end
    stroke(ctx)

    #Plot New color
    select_color(ctx,clus+1)
    
    @inbounds for i=1:han.buf_ind

        if han.buf_clus[i]==clus
            move_to(ctx,1,(han.spike_buf[1,i]-o))
            for j=2:size(han.spike_buf,1)
                line_to(ctx,j,han.spike_buf[j,i]-o)
            end
        end
    end
    stroke(ctx)

    identity_matrix(ctx)
    reveal(han.c2)

    nothing
end

function draw_c3(rhd::RHD2000,han::Gui_Handles)

    ctx=Cairo.getgc(han.c3)

    spike_num=han.spike
    reads=han.draws

    for i=1:rhd.nums[spike_num]
    
        @inbounds move_to(ctx,reads,(rhd.buf[i,spike_num].id-1)*10.0+150.0)
        @inbounds line_to(ctx,reads,(rhd.buf[i,spike_num].id-1)*10.0+160.0)
        set_line_width(ctx,0.5);
	@inbounds select_color(ctx,rhd.buf[i,spike_num].id)
	stroke(ctx)
    end

    if reads==1
        draw_templates(rhd,han)
        draw_isi(rhd,han)
    end

    nothing
end
