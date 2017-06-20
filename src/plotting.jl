#=
Plots detected spike on canvas for multiple channels
=#

draw_spike16(rhd::RHD2000,han::Gui_Handles)=draw_spike_n(rhd,han,4,4,16)

draw_spike32(rhd::RHD2000,han::Gui_Handles)=draw_spike_n(rhd,han,6,6,32)

draw_spike64(rhd::RHD2000,han::Gui_Handles)=draw_spike_n(rhd,han,6,11,64)

function draw_spike_n(rhd::RHD2000,han::Gui_Handles,n_col,n_row,num_chan)
    
    k_in=num_chan*(han.num16)-num_chan+1

    if (k_in+num_chan-1)>size(rhd.v,2)
        num_chan=(size(rhd.v,2)-k_in+1)
    end

    num_plot =n_col*n_row
    
    maxid=find_max_id(rhd,han,k_in,num_chan)
    ctx=getgc(han.c)
    xwidth=width(ctx)
    myheight=height(ctx)
    if num_plot<64
      yheight=myheight-300
    else
      yheight=myheight
    end

    scale(ctx,xwidth/(han.wave_points/2*n_col),1)

    #subsequent IDs
    @inbounds for thisid=1:maxid
	for chan=k_in:(k_in+num_chan-1)
	    if han.enabled[chan]
	        for g=1:rhd.nums[chan]
                    if (rhd.buf[g,chan].inds.start>0)&(rhd.buf[g,chan].inds.stop<size(rhd.v,1))
                        if rhd.buf[g,chan].id==thisid

                            #Gain and offset for channel
                            s=han.scale[chan,2]
                            o=han.offset[chan]

                            #x and y position for channel location
			    startx=div(rem(chan-1,num_plot),n_row)*han.wave_points/2+1
			    starty=yheight/n_row*(rem(rem(chan-1,num_plot),n_row))+yheight/n_row/2

                            #Max and min extents for line to stay within bounding box
                            ymax=starty+yheight/n_row/2
			    ymin=starty-yheight/n_row/2

                            y=(rhd.v[rhd.buf[g,chan].inds.start,chan]-o)*s+starty
			    
			    if (y<ymin)
                               y=ymin
                            elseif (y>ymax)
                               y=ymax
                            end
                            
                            move_to(ctx,startx,y)
                            for kk=rhd.buf[g,chan].inds.start+2:2:rhd.buf[g,chan].inds.stop
                                y=(rhd.v[kk,chan]-o)*s+starty
                                if (y<ymin)
                                   y=ymin
                                elseif (y>ymax)
                                   y=ymax
                                end
                                line_to(ctx,startx,y)
                                startx+=1
                            end
                        end
                    end        
                end
	    end
            if chan>length(han.enabled)
                break
            end
	end
	set_line_width(ctx,0.25);
        @inbounds select_color(ctx,thisid)
        stroke(ctx)
    end
    
    identity_matrix(ctx)
    nothing
end

function find_max_id(rhd::RHD2000,han::Gui_Handles,k,num)

    maxid=1
    
    for i=k:(k+num-1)
        if han.enabled[i]
            for g=1:rhd.nums[i]
                if rhd.buf[g,i].id>maxid
                    maxid=rhd.buf[g,i].id
                end
            end
        end
    end
    maxid
end

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

#=
Single maximized channel plotting
=#

function draw_spike(rhd::RHD2000,han::Gui_Handles)

    spike_num=han.spike
    s=han.scale[han.spike,1]
    o=han.offset[han.spike]
    reads=han.draws

    #ctx=han.ctx2s
    ctx=copy(han.ctx2s)
    paint_with_alpha(ctx,0.0)

    Cairo.translate(ctx,0.0,han.h2/2)
    scale(ctx,han.w2/han.wave_points,s)
    
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

    set_source(han.ctx2s,ctx)
    mask_surface(han.ctx2s,ctx,0.0,0.0)
    fill(han.ctx2s)

    set_source(han.ctx2,ctx)
    mask_surface(han.ctx2,ctx,0.0,0.0)
    fill(han.ctx2)
    
    #set_source(han.ctx2,han.ctx2s)
    #paint(han.ctx2)
    
    nothing
end

function mask_surface(ctx,s,x,y)
    ccall((:cairo_mask_surface,Cairo._jl_libcairo),Void,(Ptr{Void},Ptr{Void},Float64,Float64),ctx.ptr,s.surface.ptr,x,y)
end

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

function draw_multi_chan(ctx::Cairo.CairoContext,han::Gui_Handles,k,n_row,n_col,chan_num)

    mywidth=width(ctx)

    if chan_num<64
        myheight=height(ctx)-300.0
    else
        myheight=height(ctx)
    end
    
    xbounds=get_bounds(mywidth,n_col+1)
    ybounds=get_bounds(myheight,n_row+1)
    
    for x in xbounds
        line(ctx,x,x,1,myheight)
    end
    for y in ybounds
        line(ctx,1,mywidth,y,y)
    end
    set_source_rgb(ctx,1.0,1.0,1.0)
    set_line_width(ctx,1.0)
    stroke(ctx)

    for x=1:n_col
        for y=1:n_row
            if k<=length(han.enabled)
                move_to(ctx,xbounds[x]+10.0,ybounds[y]+10.0)
                if han.enabled[k] 
                    show_text(ctx,string(k))
                else
                    show_text(ctx,string(k,"-DISABLED"))
                end
            end
            k+=1
        end
    end
    (x1_f,x2_f,y1_f,y2_f)=get_multi_dims(han,n_col,n_row,chan_num,han.num)
    draw_box(x1_f,y1_f,x2_f,y2_f,(1.0,0.0,1.0),1.0,ctx)
    nothing
end

prepare_16(ctx::Cairo.CairoContext,han::Gui_Handles)=draw_multi_chan(ctx,han,16*han.num16-15,4,4,16)

prepare_32(ctx::Cairo.CairoContext,han::Gui_Handles)=draw_multi_chan(ctx,han,32*han.num16-31,6,6,32)

prepare_64(ctx::Cairo.CairoContext,han::Gui_Handles)=draw_multi_chan(ctx,han,64*han.num16-63,11,6,64)

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

function prepare_spectrogram(ctx,han)

    myheight=height(ctx)
    mywidth=width(ctx)

    set_source_rgb(ctx,1.0,1.0,1.0)

    move_to(ctx,50.0,myheight-35)
    show_text(ctx,"-1")

    move_to(ctx,50.0,myheight-35)
    show_text(ctx,"-1.0")

    move_to(ctx,(mywidth-50.0)/2+50,myheight-35)
    show_text(ctx,"-0.5")

    move_to(ctx,mywidth-20.0,myheight-35)
    show_text(ctx,"0.0")

    move_to(ctx,mywidth/2,myheight-20)
    show_text(ctx,"Time (s)")

    move_to(ctx,10.0,myheight-140)
    rotate(ctx,-pi/2)
    show_text(ctx,"Frequency")
    identity_matrix(ctx)

    move_to(ctx,35.0,myheight-50.0)
    rotate(ctx,-pi/2)
    show_text(ctx,"0.0")
    identity_matrix(ctx)

    move_to(ctx,35.0,myheight-50-125)
    rotate(ctx,-pi/2)
    show_text(ctx,"7500")
    identity_matrix(ctx)
    
    nothing
end

function line(ctx,x1,x2,y1,y2)
    move_to(ctx,x1,y1)
    line_to(ctx,x2,y2)
    nothing
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

#Replots spikes assigned to specified cluster 
function plot_new_color(ctx::Cairo.CairoContext,han::Gui_Handles,clus::Int64)

    s=han.scale[han.spike,1]
    o=han.offset[han.spike]

    set_line_width(ctx,2.0)
    set_source(ctx,han.ctx2s)
    Cairo.translate(ctx,0.0,han.h2/2)
    scale(ctx,han.w2/han.wave_points,s)

    #Plot Noise
    @inbounds for i=1:han.buf_ind

        if han.buf_clus[i]==-1
            move_to(ctx,1,(han.spike_buf[1,i]-o))
            for j=2:size(han.spike_buf,1)
                line_to(ctx,j,han.spike_buf[j,i]-o)
            end
            han.buf_clus[i]=0
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
    set_line_width(ctx,0.5);
    stroke(ctx)

    identity_matrix(ctx)
    reveal(han.c2)

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

function replot_spikes(han::Gui_Handles)

    clear_c2(han.c2,han.spike)
    han.ctx2=getgc(han.c2)
    han.ctx2s=copy(han.ctx2)

    ctx=han.ctx2s
    s=han.scale[han.spike,1]
    o=han.offset[han.spike]

    Cairo.translate(ctx,0.0,han.h2/2)
    scale(ctx,han.w2/han.wave_points,s)

    for i=1:(han.total_clus[han.spike]+1)
        for j=1:han.buf_ind
            if (han.buf_clus[j]==(i-1))&(han.buf_mask[j])
                move_to(ctx,1,(han.spike_buf[1,j]-o))
                for jj=2:size(han.spike_buf,1)
                    line_to(ctx,jj,han.spike_buf[jj,j]-o)
                end
            end
        end
        set_line_width(ctx,0.5)
        select_color(ctx,i)
        stroke(ctx)
    end
    identity_matrix(ctx)
    set_source(han.ctx2,ctx)
    mask_surface(han.ctx2,ctx,0.0,0.0)
    fill(han.ctx2)
    reveal(han.c2)
    nothing
end

function draw_spectrogram(rhd::RHD2000,han::Gui_Handles)

    ctx=getgc(han.c)
   
    x=Gtk.cairo_surface(han.c)
    data = ccall((:cairo_image_surface_get_data,Cairo._jl_libcairo),Ptr{UInt32},(Ptr{Void},),x.ptr)
    
    c_h=round(Int64,height(ctx))
    c_w=round(Int64,width(ctx))-50

    for i=(size(rhd.v,1)+1):rhd.sr
        han.v_s[i-SAMPLES_PER_DATA_BLOCK] = han.v_s[i]
    end

    count=1
    for i=(rhd.sr-SAMPLES_PER_DATA_BLOCK+1):rhd.sr
        han.v_s[i] = rhd.v[count,han.spike]
        count+=1
    end

    S=plot_spectrogram(han.v_s,rhd.sr)

    in_w = size(S,2)
    in_h = size(S,1)

    scale_w = c_w / in_w
    scale_h = 250 / in_h

    mymin=minimum(S)
    mymax=maximum(S)
    myrange=mymax-mymin

    rgb_mat = zeros(UInt32,in_h,in_w)

    for h=1:in_h
        for w=1:in_w
        
            startround = (S[h,w]-mymin)/myrange*255
            myinput::UInt8 = (startround >= 255) ? 255 : floor(UInt8,startround)+1
        
            myblue=jet_b[myinput]
            mygreen=jet_g[myinput]
            myred=jet_r[myinput]
       
            rgb_mat[h,w] = 0
            rgb_mat[h,w] |= myblue  # blue
            rgb_mat[h,w] |= (mygreen << 8) #green
            rgb_mat[h,w] |= (myred << 16) #red
        end
    end
    
    for h=1:250
        for w=1:c_w
            val = rgb_mat[ceil(Int,h/scale_h),ceil(Int,w/scale_w)]
            unsafe_store!(data,val,(c_h-h-50)*(c_w+50)+w+50)
        end
    end
    
    nothing
end

function plot_spectrogram(s,fs)
    win_width_t = .01
    win_overlap_t = .002
    
    win_width_s=convert(Int, win_width_t*fs)
    win_overlap_s=convert(Int, win_overlap_t*fs)
    S = spectrogram(s,win_width_s,win_overlap_s; fs=fs, window=hanning)
    log10(power(S))
end
