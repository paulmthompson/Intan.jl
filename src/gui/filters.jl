
#=
Filtering
=#

function make_filter(rhd::RHD2000,filter_type::String,wn1,wn2=0.0)

    if filter_type == "High Pass"
        responsetype = Highpass(wn1; fs = rhd.sr)
    elseif filter_type == "Low Pass"
        responsetype = Lowpass(wn1; fs = rhd.sr)
    elseif filter_type == "BandPass"
        responsetype = Bandpass(wn1,wn2; fs=rhd.sr)
    elseif filter_type == "BandStop"
        responsetype = Bandstop(wn1,wn2; fs=rhd.sr)
    end
    designmethod=Butterworth(4)
    df1=digitalfilter(responsetype,designmethod)
    DF2TFilter(df1)
end

function apply_filter(rhd::RHD2000,ff::MyFilter,chan_num::Int64)

    temp=zeros(Float64,SAMPLES_PER_DATA_BLOCK)
    for i=1:SAMPLES_PER_DATA_BLOCK
        temp[i]=convert(Float64,rhd.v[i,chan_num])
    end

    filt!(temp,ff,temp)

    for i=1:SAMPLES_PER_DATA_BLOCK
        rhd.v[i,chan_num] = round(Int16,temp[i])
    end
    nothing
end

#=
Callbacks
=#

function filter_type_cb(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han,rhd = user_data

    filter_type = unsafe_string(Gtk.GAccessor.active_text(han.band_widgets.sw_box))

    if filter_type == "High Pass"
        Gtk.visible(han.band_widgets.wn_sb1,true)
        Gtk.visible(han.band_widgets.wn_sb2,false)
        setproperty!(han.band_widgets.wn_sb1_l,:label,"High Pass Cutoff")
        setproperty!(han.band_widgets.wn_sb2_l,:label,"")
    elseif filter_type == "Low Pass"
        Gtk.visible(han.band_widgets.wn_sb1,true)
        Gtk.visible(han.band_widgets.wn_sb2,false)
        setproperty!(han.band_widgets.wn_sb1_l,:label,"Low Pass Cutoff")
        setproperty!(han.band_widgets.wn_sb2_l,:label,"")
    elseif filter_type == "BandPass"
        Gtk.visible(han.band_widgets.wn_sb1,true)
        Gtk.visible(han.band_widgets.wn_sb2,true)
        setproperty!(han.band_widgets.wn_sb1_l,:label,"Low Cutoff")
        setproperty!(han.band_widgets.wn_sb2_l,:label,"High Cutoff")
    elseif filter_type == "BandStop"
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
    
    filt_type = unsafe_string(Gtk.GAccessor.active_text(han.band_widgets.sw_box))

    chan_num = getproperty(han.band_widgets.sw_chan_sb,:value,Int64)

    wn1 = getproperty(han.band_widgets.wn_sb1,:value,Int64)
    wn2 = getproperty(han.band_widgets.wn_sb2,:value,Int64)

    if (getproperty(han.band_widgets.sw_check,:active,Bool))
        for i=1:size(rhd.v,2)
            myfilt=make_filter(rhd,filt_type,wn1,wn2)
            push!(rhd.filts,Intan_Filter(i,myfilt))
            push!(han.band_widgets.list,(i,filt_type,wn1,wn2))
        end
    else
        #add new filter
        myfilt=make_filter(rhd,filt_type,wn1,wn2)
        push!(rhd.filts,Intan_Filter(chan_num,myfilt))
        push!(han.band_widgets.list,(chan_num,filt_type,wn1,wn2))
    end

    nothing
end

function replace_filter_cb(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han,rhd = user_data

    filt_type = unsafe_string(Gtk.GAccessor.active_text(han.band_widgets.sw_box))

    chan_num = getproperty(han.band_widgets.sw_chan_sb,:value,Int64)

    wn1 = getproperty(han.band_widgets.wn_sb1,:value,Int64)
    wn2 = getproperty(han.band_widgets.wn_sb2,:value,Int64)

    for i=0:(length(han.band_widgets.list)-1)
        if is_selected(han.band_widgets.list,han.band_widgets.tv,i)
            #Replace Table values
            setindex!(han.band_widgets.list,filt_type,i+1,2)
            setindex!(han.band_widgets.list,wn1,i+1,3)
            setindex!(han.band_widgets.list,wn2,i+1,4)

            #Replace actual filter
            myfilt=make_filter(rhd,filt_type,wn1,wn2)
            rhd.filts[i+1]=Intan_Filter(rhd.filts[i+1].chan,myfilt)
        end
    end

    
    nothing
end

function band_adj_cb(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})
    han, rhd = user_data

    visible(han.band_widgets.win,true)
end

function band_b1_cb{I<:IC}(widget::Ptr,user_data::Tuple{Gui_Handles,Array{I,1}})

    han, myic = user_data

    lower=getproperty(han.band_widgets.sb1,:value,Int64)
    upper=getproperty(han.band_widgets.sb2,:value,Int64)
    dsp_lower=getproperty(han.band_widgets.sb3,:value,Int64)

    change_bandwidth(myic,lower,upper,dsp_lower)
    
    nothing
end
