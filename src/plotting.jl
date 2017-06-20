

function draw_raster_n(rhd::RHD2000,han::Gui_Handles,num_chan::Int64)

    num_plot=num_chan
    
    k_in=num_chan*(han.num16)-num_chan+1

    if (k_in+num_chan-1)>size(rhd.v,2)
        num_chan=(size(rhd.v,2)-k_in+1)
    end
    
    maxid=find_max_id(rhd,han,k_in,num_chan)
    ctx=getgc(han.c)

    xwidth=width(ctx)
    myheight=height(ctx)
    if num_plot<64
        yheight=300
        myoff=myheight-300.0
    else
        yheight=myheight
        myoff=0.0
    end

    ctx_step=yheight/num_chan
    
    @inbounds for thisid=1:maxid
        count=1
        for i=k_in:(k_in+num_chan-1)
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

draw_raster16(rhd::RHD2000,han::Gui_Handles)=draw_raster_n(rhd,han,16)

draw_raster32(rhd::RHD2000,han::Gui_Handles)=draw_raster_n(rhd,han,32)

draw_raster64(rhd::RHD2000,han::Gui_Handles)=draw_raster_n(rhd,han,64)

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

    ctx=getgc(han.c3)

    myheight=height(ctx)
    mywidth=width(ctx)

    total_clus = max(han.total_clus[han.spike]+1,5)
    
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
        startx=(i-1)*(han.wave_points)+1
        scale(ctx,mywidth/(han.wave_points*total_clus),1)
        move_to(ctx,startx,10)
        show_text(ctx,string(isi_f))


        #Find Scale for histogram
        isi_scale = (maximum(han.isi_hist)>0) ? 50/maximum(han.isi_hist) : 1
        
        select_color(ctx,i+1)
        move_to(ctx,startx,130)
        line_to(ctx,startx,130-han.isi_hist[1]*isi_scale)
        han.isi_hist[1]=0

        for j=2:length(han.isi_hist)
            if j < han.wave_points
                move_to(ctx,startx+j,130)
                line_to(ctx,startx+j,130-han.isi_hist[j]*isi_scale)
            end
            han.isi_hist[j]=0
        end
        stroke(ctx)

        identity_matrix(ctx)
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
    elseif han.c_right_bottom==7
        prepare_spectrogram(ctx,han)
    else
        
    end
    nothing
end

get_bounds(mydim,divs)=linspace(0.0,mydim,divs)

function prepare_raster16(ctx)
end

function prepare_raster32(ctx)
end

function prepare_events(ctx,han)

    myheight=height(ctx)

    for y in collect((myheight-250.0):50.0:(myheight-50.0))
        line(ctx,1.0,500.0,y,y)
    end
    set_source_rgb(ctx,1.0,1.0,1.0)
    set_line_width(ctx,1.0)
    stroke(ctx)

    for i=1:6
	if han.events[i]>-1
            move_to(ctx,10,(myheight-340)+i*50)
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
end
 
function clear_c2(myc::Gtk.GtkCanvas,num)
        
    ctx = getgc(myc)
    myheight=height(ctx)
    mywidth=width(ctx)

    set_source_rgb(ctx,0.0,0.0,0.0)
    paint(ctx)

    dashes = [10.0,10.0,10.0]
    set_dash(ctx, dashes, 0.0)
    
    for y = [myheight/6, myheight/3, myheight/2, myheight/6*4, myheight/6*5]
        line(ctx,1,mywidth,y,y)
    end

    for x = [.2*mywidth, .4*mywidth, .6*mywidth, .8*mywidth]
        line(ctx,x,x,1,myheight)
    end

    set_source_rgba(ctx,1.0,1.0,1.0,.5)
    stroke(ctx) 
    
    set_dash(ctx,Float64[])

    line(ctx,1,mywidth,myheight,myheight)
    set_source_rgb(ctx,1.0,1.0,1.0)
    stroke(ctx)

    line(ctx,1,mywidth,myheight/2,myheight/2)
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

function draw_c3(rhd::RHD2000,han::Gui_Handles)

    ctx=Cairo.getgc(han.c3)
    mywidth=width(ctx)

    spike_num=han.spike
    reads=han.draws

    scale(ctx,mywidth/500.0,1.0)

    for i=1:rhd.nums[spike_num]
    
        @inbounds move_to(ctx,reads,(rhd.buf[i,spike_num].id-1)*10.0+150.0)
        @inbounds line_to(ctx,reads,(rhd.buf[i,spike_num].id-1)*10.0+160.0)
        set_line_width(ctx,0.5);
	@inbounds select_color(ctx,rhd.buf[i,spike_num].id)
	stroke(ctx)
    end

    identity_matrix(ctx)

    if reads==1
        prepare_c3(rhd,han)
        draw_templates_c3(han)
        draw_isi(rhd,han)
    end

    nothing
end

function prepare_c3(rhd::RHD2000,han::Gui_Handles)

    ctx=getgc(han.c3)

    myheight=height(ctx)
    mywidth=width(ctx)

    total_clus = max(han.total_clus[han.spike]+1,5)

    line(ctx,0,mywidth,130,130)
    set_source_rgb(ctx,1.0,1.0,1.0)
    stroke(ctx)

    scale(ctx,mywidth/(han.wave_points*total_clus),1)

    for i=1:total_clus

        line(ctx,i*han.wave_points,i*han.wave_points,0,130)
        set_source_rgb(ctx,1.0,1.0,1.0)
        stroke(ctx)

    end

    identity_matrix(ctx)

    if han.clus>0
        (x1_f,x2_f,y1_f,y2_f)=get_template_dims(han,han.clus)
        draw_box(x1_f,y1_f,x2_f,y2_f,(1.0,0.0,1.0),1.0,ctx)
    end

    nothing
end

