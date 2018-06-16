

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
    show_text(ctx,string(round(Int64,han.spect.f_max*han.spect.f_div/2)))
    identity_matrix(ctx)
    
    nothing
end

function draw_spectrogram(rhd::RHD2000,han::Gui_Handles)

    ctx=Gtk.getgc(han.c)
   
    x=Gtk.cairo_surface(han.c)
    data = ccall((:cairo_image_surface_get_data,Cairo._jl_libcairo),Ptr{UInt32},(Ptr{Void},),x.ptr)
    
    c_h=round(Int64,height(ctx))
    c_w=round(Int64,width(ctx))-50

    for i=(size(rhd.v,1)+1):rhd.sr
        han.v_s[i-SAMPLES_PER_DATA_BLOCK] = han.v_s[i]
    end
    count=1
    
    if han.band_widgets.lfp_en[han.spike]
        for i=(rhd.sr-SAMPLES_PER_DATA_BLOCK+1):rhd.sr
            han.v_s[i] = rhd.lfps[count,han.spike]
            count+=1
        end
    else
        for i=(rhd.sr-SAMPLES_PER_DATA_BLOCK+1):rhd.sr
            han.v_s[i] = rhd.v[count,han.spike]
            count+=1
        end
    end

    plot_spectrogram(han.v_s,rhd.sr,han.spect)

    in_w = han.spect.t_max
    in_h = han.spect.f_max

    scale_w = c_w / in_w
    scale_h = 250 / in_h

    mymin=minimum(han.spect.out)
    mymax=maximum(han.spect.out)
    myrange=mymax-mymin

    rgb_mat = zeros(UInt32,in_h,in_w)

    for h=1:in_h
        for w=1:in_w
        
            startround = (han.spect.out[h,w]-mymin)/myrange*255
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

function plot_spectrogram(s,fs,spect)

    S = spectrogram(s,spect.win_width_s,spect.win_overlap_s; fs=fs, window=hanning)

    temp = power(S)

    for i=1:spect.f_max
        for j=1:spect.t_max
            spect.out[i,j]=log10(temp[i,j])
        end
    end
    
    nothing
end

function spect_popup_freq_cb(widget::Ptr,user_data::Tuple{Gui_Handles,Int64})

    han, event_id = user_data

    if event_id == 0
        f_max = 300
    elseif event_id == 1
        f_max = 1000
    elseif event_id == 2
        f_max = 3000
    elseif event_id == 3
        f_max = 7500
    else
        f_max = 15000
    end

    han.spect = Spectrogram(han.spect.fs; win_width_t = han.spect.win_width_t, win_overlap_t = han.spect.win_overlap_t, f_max = f_max)

    nothing
end

function spect_popup_win_cb(widget::Ptr,user_data::Tuple{Gui_Handles,Int64})

    han, event_id = user_data


    if event_id == 0
        mywin = .01
    elseif event_id == 1
        mywin = .05
    else
        mywin = .1
    end

    han.spect = Spectrogram(han.spect.fs; win_width_t = mywin, win_overlap_t = han.spect.win_overlap_t, f_max = han.spect.f_max*han.spect.f_div)
    
    nothing
end
