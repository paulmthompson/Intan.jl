

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
