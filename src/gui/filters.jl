
#=
Filtering
=#

function make_filter(rhd::RHD2000,filter_type::Int64,wn1,wn2=0.0)

    if filter_type == 1
        responsetype = Highpass(wn1; fs = rhd.sr)
    elseif filter_type == 2
        responsetype = Lowpass(wn1; fs = rhd.sr)
    elseif filter_type == 3
        responsetype = Bandpass(wn1,wn2; fs=rhd.sr)
    elseif filter_type == 4
        responsetype = Bandstop(wn1,wn2; fs=rhd.sr)
    end
    designmethod=Butterworth(4)
    df1=digitalfilter(responsetype,designmethod)
    DF2TFilter(df1)
end

function apply_filter(rhd::RHD2000,ff::Intan_Filter,chan_num::Int64)

    temp=zeros(Float64,SAMPLES_PER_DATA_BLOCK)
    for i=1:SAMPLES_PER_DATA_BLOCK
        temp[i]=convert(Float64,rhd.v[i,chan_num])
    end

    filt!(temp,ff.filt,temp)

    if ff.output==0
        for i=1:SAMPLES_PER_DATA_BLOCK
            rhd.v[i,chan_num] = round(Int16,temp[i])
        end
    else
        for i=1:SAMPLES_PER_DATA_BLOCK
            rhd.lfps[i,chan_num] = round(Int16,temp[i])
        end
    end
    nothing
end

#=
Callbacks
=#

function filter_type_cb(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han,rhd = user_data

    filter_type = getproperty(han.band_widgets.sw_box,:active,Int64)+1
    han.band_widgets.f_type = filter_type

    if filter_type == 1
        Gtk.visible(han.band_widgets.wn_sb1,true)
        Gtk.visible(han.band_widgets.wn_sb2,false)
        setproperty!(han.band_widgets.wn_sb1_l,:label,"High Pass Cutoff")
        setproperty!(han.band_widgets.wn_sb2_l,:label,"")
    elseif filter_type == 2
        Gtk.visible(han.band_widgets.wn_sb1,true)
        Gtk.visible(han.band_widgets.wn_sb2,false)
        setproperty!(han.band_widgets.wn_sb1_l,:label,"Low Pass Cutoff")
        setproperty!(han.band_widgets.wn_sb2_l,:label,"")
    elseif filter_type == 3
        Gtk.visible(han.band_widgets.wn_sb1,true)
        Gtk.visible(han.band_widgets.wn_sb2,true)
        setproperty!(han.band_widgets.wn_sb1_l,:label,"Low Cutoff")
        setproperty!(han.band_widgets.wn_sb2_l,:label,"High Cutoff")
    elseif filter_type == 4
        Gtk.visible(han.band_widgets.wn_sb1,true)
        Gtk.visible(han.band_widgets.wn_sb2,true)
        setproperty!(han.band_widgets.wn_sb1_l,:label,"Low Cutoff")
        setproperty!(han.band_widgets.wn_sb2_l,:label,"High Cutoff")
    end

    nothing
end

function add_filter_cb(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    #Create Filter
    han,rhd = user_data

    filt_type = han.band_widgets.f_type

    chan_num = han.band_widgets.chan

    wn1 = han.band_widgets.wn1
    wn2 = han.band_widgets.wn2

    pos = han.band_widgets.f_pos

    output = han.band_widgets.f_out

    if (getproperty(han.band_widgets.sw_check,:active,Bool))
        for i=1:size(rhd.v,2)
            myfilt=make_filter(rhd,filt_type,wn1,wn2)
            if pos > length(rhd.filts[i])
                push!(rhd.filts[i],Intan_Filter(i,output,wn1,wn2,filt_type,myfilt))
            else
                insert!(rhd.filts[i],pos,Intan_Filter(i,output,wn1,wn2,filt_type,myfilt))
            end

            if output==1
                han.band_widgets.lfp_en[i]=true
            end
        end
    else
        #add new filter
        myfilt=make_filter(rhd,filt_type,wn1,wn2)
        if pos>length(rhd.filts[chan_num])
            push!(rhd.filts[chan_num],Intan_Filter(chan_num,output,wn1,wn2,filt_type,myfilt))
        else
            insert!(rhd.filts[chan_num],pos,Intan_Filter(chan_num,output,wn1,wn2,filt_type,myfilt))
        end
        if output==1
            han.band_widgets.lfp_en[chan_num]=true
        end
    end

    draw_filter_canvas(han,rhd,chan_num)
    Gtk.GAccessor.range(han.band_widgets.filt_num_sb,1,length(rhd.filts[chan_num])+1)

    nothing
end

function replace_filter_cb(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han,rhd = user_data

    filt_type = han.band_widgets.f_type

    chan_num = han.band_widgets.chan

    wn1 = han.band_widgets.wn1
    wn2 = han.band_widgets.wn2

    pos = han.band_widgets.f_pos

    output = han.band_widgets.f_out

    myfilt=make_filter(rhd,filt_type,wn1,wn2)

    if rhd.filts[chan_num][pos].f_out == 1
        if output == 0
            han.band_widgets.lfp_en[chan_num]=false
        end
    end
    if output == 1
        han.band_widgets.lfp_en[chan_num]=true
    end

    rhd.filts[chan_num][pos]=Intan_Filter(rhd.filts[chan_num][pos].chan,output,wn1,wn2,filt_type,myfilt)

    draw_filter_canvas(han,rhd,pos)

    nothing
end

function band_adj_cb(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})
    han, rhd = user_data

    visible(han.band_widgets.win,true)
end

function band_b1_cb(widget::Ptr,user_data::Tuple{Gui_Handles,Array{I,1}}) where I<:IC

    han, myic = user_data

    lower=getproperty(han.band_widgets.sb1,:value,Int64)
    upper=getproperty(han.band_widgets.sb2,:value,Int64)
    dsp_lower=getproperty(han.band_widgets.sb3,:value,Int64)

    change_bandwidth(myic,lower,upper,dsp_lower)

    nothing
end

function change_wn1_cb(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han,rhd = user_data

    han.band_widgets.wn1 = getproperty(han.band_widgets.wn_sb1,:value,Int64)

    draw_filter_canvas(han,rhd,han.band_widgets.f_pos)

    nothing
end

function change_wn2_cb(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han,rhd = user_data

    han.band_widgets.wn2 = getproperty(han.band_widgets.wn_sb2,:value,Int64)

    draw_filter_canvas(han,rhd,han.band_widgets.f_pos)

    nothing
end

function change_pos_cb(widget::Ptr,user_data::Tuple{RHD2000,Gui_Handles})

    rhd, han = user_data

    han.band_widgets.f_pos=getproperty(han.band_widgets.filt_num_sb,:value,Int64)

    draw_filter_canvas(han,rhd,han.band_widgets.f_pos)

    nothing
end

function change_filt_output_cb(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han,rhd = user_data

    han.band_widgets.f_out = getproperty(han.band_widgets.output_box,:active,Int64)

    draw_filter_canvas(han,rhd,han.band_widgets.f_pos)

    nothing
end

function delete_filter_cb(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han,rhd = user_data

    if han.band_widgets.f_pos > length(rhd.filts[han.band_widgets.chan])
    else

        if rhd.filts[han.band_widgets.chan][han.band_widgets.f_pos].output == 1
            han.band_widgets.lfp_en[han.band_widgets.chan] = false
        end

        deleteat!(rhd.filts[han.band_widgets.chan],han.band_widgets.f_pos)

        setproperty!(han.band_widgets.filt_num_sb,:value,1)

        Gtk.GAccessor.range(han.band_widgets.filt_num_sb,1,length(rhd.filts[han.band_widgets.chan])+1)

        draw_filter_canvas(han,rhd,han.band_widgets.f_pos)
    end

    nothing
end

function change_channel_cb(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data

    han.band_widgets.chan=getproperty(han.band_widgets.sw_chan_sb,:value,Int64)

    Gtk.GAccessor.range(han.band_widgets.filt_num_sb,1,length(rhd.filts[han.band_widgets.chan])+1)

    setproperty!(han.band_widgets.filt_num_sb,:value,1)

    draw_filter_canvas(han,rhd,1)

    nothing
end

function draw_filter_canvas(han::Gui_Handles,rhd,pos)

    ctx = Gtk.getgc(han.band_widgets.c)

    set_source_rgb(ctx,1.0,1.0,1.0)
    paint(ctx)
    set_source_rgb(ctx,0.0,0.0,0.0)

    num=han.band_widgets.chan

    draw_hardware_filter(han,num,ctx)

    split=false
    lr=1

    for i=1:length(rhd.filts[num])

        if rhd.filts[num][i].output==1
            lr=0
            split=true
        elseif split
            lr=2
        else
            lr=1
        end

        if i != pos
            draw_software_filter(rhd.filts[num][i],ctx,i,lr,(0.0,0.0,0.0),false)
        else
            draw_software_filter(Intan_Filter(num,han.band_widgets.f_out,han.band_widgets.wn1,han.band_widgets.wn2,han.band_widgets.f_type,make_filter(rhd,1,10,10)),ctx,i,lr,(1.0,0.0,0.0),false)
        end
    end

    if pos>length(rhd.filts[num])
        if han.band_widgets.f_out==1
            lr=0
            split=true
        elseif split
            lr=2
        else
            lr=1
        end
        draw_software_filter(Intan_Filter(num,han.band_widgets.f_out,han.band_widgets.wn1,han.band_widgets.wn2,han.band_widgets.f_type,make_filter(rhd,1,10,10)),ctx,pos,lr,(1.0,0.0,0.0),true)
    end

    reveal(han.band_widgets.c)
    nothing
end

function draw_hardware_filter(han,num,ctx)

    move_to(ctx,30,15)
    show_text(ctx,"RHD Hardware")
    move_to(ctx,30,25)
    show_text(ctx,string("Analog Bandpass: ",300," - ",3000))
    move_to(ctx,30,35)
    show_text(ctx,string("Hardware Highpass DSP: ",300))

    draw_box(25,5,175,45,(0.0,0.0,0.0),1.0,ctx)

    nothing
end

function draw_software_filter(myfilt,ctx,i,lr,mycolor,myselect)

    yinit=85+(i-1)*80

    if lr==0 #LFP left
        x1=25
        x2=100
        line(ctx,x1,x1,yinit-40,yinit+5)
        line(ctx,175,175,yinit-40,yinit+85)
        line(ctx,x1,50,yinit-40,yinit-40)
        line(ctx,150,175,yinit-40,yinit-40)
    elseif lr==1
        x1=50
        x2=150
        line(ctx,100,100,yinit-40,yinit+5)
    else
        x1=100
        x2=175
        line(ctx,x2,x2,yinit-40,yinit+5)
    end

    if myselect
        dashes=[5.0,5.0,5.0]
        set_dash(ctx,dashes,0.0)
    end

    draw_box(x1,yinit+5,x2,yinit+45,mycolor,1.0,ctx)

    if myselect
        set_dash(ctx,Float64[])
    end


    wn1 = myfilt.wn1
    wn2 = myfilt.wn2

    move_to(ctx,x1+5,yinit+15)
    if (myfilt.f_type==1)|(myfilt.f_type==2)

        if myfilt.f_type==1
            show_text(ctx,"High Pass")
        else
            show_text(ctx,"Low Pass")
        end
        move_to(ctx,x1+5,yinit+25)
        show_text(ctx,string("Cutoff: ", wn1))
    else

        if myfilt.f_type==3
            show_text(ctx,"BandPass")
        else
            show_text(ctx,"BandStop")
        end
        move_to(ctx,x1+5,yinit+25)
        show_text(ctx,string("Band: ", wn1, " - ", wn2))
    end

    nothing
end
