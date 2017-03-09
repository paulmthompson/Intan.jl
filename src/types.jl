
export SaveWave,SaveAll,SaveNone, FPGA

abstract RHD2000
abstract Task
abstract SaveOpt

global num_rhd = 0

type Debug
    state::Bool
    m::String
    data::Array{Float64,1}
    ind::Int64
    maxind::Int64
end

type SaveWave <: SaveOpt 
end

type SaveAll <: SaveOpt
    v::String
    ts::String
    adc::String
    ttl::String
    folder::String
end

function SaveAll()

    @static if is_unix()
        t=string("./",now())
        out=SaveAll(string(t,"/v.bin"),string(t,"/ts.bin"),string(t,"/adc.bin"),string(t,"/ttl.bin"),t)
    end

    @static if is_windows()
        t=Dates.format(now(),"yyyy-mm-dd-HH-MM-SS")
        out=SaveAll(string(t,"\\v.bin"),string(t,"\\ts.bin"),string(t,"\\adc.bin"),string(t,"\\ttl.bin"),t)
    end
    out
end

type SaveNone <: SaveOpt
    ts::String
    adc::String
    ttl::String
    folder::String
end

function SaveNone()

    @static if is_unix()
        t=string("./",now())
        out=SaveNone(string(t,"/ts.bin"),string(t,"/adc.bin"),string(t,"/ttl.bin"),t)
    end

    @static if is_windows()
	t=Dates.format(now(),"yyyy-mm-dd-HH-MM-SS")
        out=SaveNone(string(t,"\\ts.bin"),string(t,"\\adc.bin"),string(t,"\\ttl.bin"),t)
    end
    out
end

type WIFI
    enabled::Bool
    buff::Int64
end

WIFI()=WIFI(false,1)


type register
    sampleRate::Cdouble

    #Register 0 variables
    adcReferenceBw::Int32
    ampFastSettle::Int32
    ampVrefEnable::Int32
    adcComparatorBias::Int32
    adcComparatorSelect::Int32

    #Register 1 variables
    vddSenseEnable::Int32
    adcBufferBias::Int32

    #Register 2 variables
    muxBias::Int32

    #Register 3 variables
    muxLoad::Int32
    tempS1::Int32
    tempS2::Int32
    tempEn::Int32
    digOutHiZ::Int32
    digOut::Int32

    #Register 4 variables
    weakMiso::Int32
    twosComp::Int32
    absMode::Int32
    dspEn::Int32
    dspCutoffFreq::Int32

    #Register 5 variables
    zcheckDacPower::Int32
    zcheckLoad::Int32
    zcheckScale::Int32
    zcheckConnAll::Int32
    zcheckSelPol::Int32
    zcheckEn::Int32

    #Register 6 variables

    #Register 7 variables
    zcheckSelect::Int32

    #Register 8-13 variables
    offChipRH1::Int32
    offChipRH2::Int32
    offChipRL::Int32
    adcAux1En::Int32
    adcAux2En::Int32
    adcAux3En::Int32
    rH1Dac1::Int32
    rH1Dac2::Int32
    rH2Dac1::Int32
    rH2Dac2::Int32
    rLDac1::Int32
    rLDac2::Int32
    rLDac3::Int32

    #Register 14-17 variables
    aPwr::Array{Int32,1}

end

type FPGA
    id::Int64
    board::Ptr{Void}
    lib::Ptr{Void}
    shift::Int64
    sampleRate::Int64
    numDataStreams::Int64
    dataStreamEnabled::Array{Int64,2}
    usbBuffer::Array{UInt8,1}
    numWords::Int64
    numBytesPerBlock::Int64
    amps::Array{Int64,1}
    adc::Array{UInt16,2}
    ttlin::Array{UInt16,1}
    ttlout::Array{UInt16,1}
    ttloutput::UInt16
    usb3::Bool
    r::register
end

function FPGA(board_id::Int64,amps::Array{Int64,1})
    board = Ptr{Void}(1)
    mylib = Ptr{Void}(1)
    if board_id==1
        FPGA(1,board,mylib,0,30000,0,zeros(Int64,1,MAX_NUM_DATA_STREAMS),zeros(UInt8,USB_BUFFER_SIZE),0,0,amps,zeros(UInt16,SAMPLES_PER_DATA_BLOCK,8),zeros(UInt16,SAMPLES_PER_DATA_BLOCK),zeros(UInt16,SAMPLES_PER_DATA_BLOCK),0,false,CreateRHD2000Registers(30000))
    elseif board_id==2
        FPGA(2,board,mylib,0,30000,0,zeros(Int64,1,MAX_NUM_DATA_STREAMS),zeros(UInt8,USB_BUFFER_SIZE),0,0,amps,zeros(UInt16,SAMPLES_PER_DATA_BLOCK,8),zeros(UInt16,SAMPLES_PER_DATA_BLOCK),zeros(UInt16,SAMPLES_PER_DATA_BLOCK),0,false,CreateRHD2000Registers(30000))
    end
end

function gen_rhd(fpga,v,prev,s,buf,nums,tas,sav,filts,mytime)

    global num_rhd

    num_rhd+=1
    k=num_rhd
    
    @eval begin
        type $(Symbol("RHD200$k")) <: RHD2000
            fpga::$(typeof(fpga))
            v::$(typeof(v))
            prev::$(typeof(prev))
            s::$(typeof(s))
            buf::$(typeof(buf))
            nums::$(typeof(nums))
            debug::Debug
            reads::Int64
            cal::Int64
            task::$(typeof(tas))
            save::$(typeof(sav))
            filts::$(typeof(filts))
            sr::Int64
            refs::Array{Int64,1}
            ttl_state::Bool
            time::$(typeof(mytime))
            wifi::WIFI
        end

        function make_rhd(fpga::$(typeof(fpga)),v::$(typeof(v)),prev::$(typeof(prev)),s::$(typeof(s)),buf::$(typeof(buf)),nums::$(typeof(nums)),debug::Debug,tas::$(typeof(tas)),sav::$(typeof(sav)),filts::$(typeof(filts)),mytime::$(typeof(mytime)))
            
            $(Symbol("RHD200$k"))(fpga,v,prev,s,buf,nums,debug,0,0,tas,sav,filts,30000,zeros(Int64,size(v,2)),false,mytime,WIFI())
        end
    end
end

default_sort=Algorithm[DetectNeg(),ClusterTemplate(49),AlignMin(),FeatureTime(),ReductionNone(),ThresholdMeanN()]

debug_sort=Algorithm[DetectNeg(),ClusterTemplate(49),AlignMinMax(),FeatureTime(),ReductionNone(),ThresholdMeanN()]

default_debug=Debug(false,"off",zeros(Float64,1),0,0)

default_save=SaveAll()

function makeRHD(fpga::Array{FPGA,1},mytask::Task; params=default_sort, parallel=false, debug=default_debug,sav=default_sav,sr=30000,wave_time=1.6,usb3=false,wifi=false)

    c_per_fpga=[length(fpga[i].amps)*32 for i=1:length(fpga)]

    if length(c_per_fpga)>1
        for i=2:length(c_per_fpga)
            fpga[i].shift=c_per_fpga[i-1]
        end
    end
    
    numchannels=sum(c_per_fpga)
                  
    if debug.state==true
        params=debug_sort
    end

    notches=[make_notch(59,61,sr) for i=1:numchannels]

    wave_points=get_wavelength(sr,wave_time)
    
    if parallel==false
        v=zeros(Int16,SAMPLES_PER_DATA_BLOCK,numchannels)
        prev=zeros(Float64,SAMPLES_PER_DATA_BLOCK)
        s=create_multi(params...,numchannels,wave_points)
        (buf,nums)=output_buffer(numchannels)
        mytime=zeros(UInt32,SAMPLES_PER_DATA_BLOCK,length(fpga))
        if usb3==true
            for myfpga in fpga
                myfpga.usb3=true
            end
        end
    else
        v=convert(SharedArray{Int16,2},zeros(Int64,SAMPLES_PER_DATA_BLOCK,numchannels))
        prev=convert(SharedArray{Float64,1},zeros(Int64,SAMPLES_PER_DATA_BLOCK))
        s=create_multi(params...,numchannels,workers()[1]:workers()[end],wave_points)
        (buf,nums)=output_buffer(numchannels,true)
        if usb3==true
            for myfpga in fpga
                myfpga.usb3=true
            end
        end
        fpga=distribute(fpga)
        mytime=zeros(UInt32,SAMPLES_PER_DATA_BLOCK,length(fpga))
        mytime=convert(SharedArray{UInt32,2},mytime)
    end

    
    gen_rhd(fpga,v,prev,s,buf,nums,mytask,sav,notches,mytime)
    rhd=make_rhd(fpga,v,prev,s,buf,nums,debug,mytask,sav,notches,mytime)

    rhd.sr=sr

    if wifi==true
        #Spawn a UDP listener thread to receive wireless packets
        udp_listener()
        rhd.wifi.enabled=true
    end

    rhd
end

function make_notch(wn1,wn2,sr)
    responsetype = Bandstop(wn1,wn2; fs=sr)
    designmethod = Butterworth(4)
    df1=digitalfilter(responsetype, designmethod)
    DF2TFilter(df1)
end

get_wavelength(sr,timewin)=round(Int,sr*timewin/1000)

type mytime
    h::Int8
    h_l::Gtk.GtkLabelLeaf
    m::Int8
    m_l::Gtk.GtkLabelLeaf
    s::Int8
    s_l::Gtk.GtkLabelLeaf
end

type SoftScope
    v::Array{Float64,1}
    ind::Int64
    last::Array{Float64,1}
    v_div::Float64
    t_div::Float64
    draws::Int64
    spikes::Array{Int64,1}
    num_spikes::Int64
    prev_spikes::Array{Int64,1}
    prev_num_spikes::Int64
    thres_on::Bool
end

function SoftScope(sr)
    SoftScope(zeros(Float64,5120),1,zeros(Float64,512),1.0/1000,1.0,1,zeros(Int64,500),0,zeros(Int64,500),0,false)
end

type Band_Widgets
    win::Gtk.GtkWindowLeaf
    sb1::Gtk.GtkSpinButtonLeaf
    sb2::Gtk.GtkSpinButtonLeaf
    sb3::Gtk.GtkSpinButtonLeaf
    b1::Gtk.GtkButtonLeaf
end

type Sort_Widgets
   b1::Gtk.GtkButtonLeaf
   b2::Gtk.GtkButtonLeaf
   b3::Gtk.GtkButtonLeaf
   b4::Gtk.GtkButtonLeaf
   check::Gtk.GtkCheckButtonLeaf
end

type Thres_Widgets
    slider::Gtk.GtkScaleLeaf
    adj::Gtk.GtkAdjustmentLeaf
    all::Gtk.GtkCheckButtonLeaf
    show::Gtk.GtkCheckButtonLeaf
end

type Gain_Widgets
    gainbox::Gtk.GtkSpinButtonLeaf
    offbox::Gtk.GtkSpinButtonLeaf
    multiply::Gtk.GtkCheckButtonLeaf
    all::Gtk.GtkCheckButtonLeaf
end

type Spike_Widgets
    hold::Gtk.GtkCheckButtonLeaf
    buf::Gtk.GtkCheckButtonLeaf
    refresh::Gtk.GtkButtonLeaf
    pause::Gtk.GtkToggleButtonLeaf
end

type Gui_Handles
    win::Gtk.GtkWindowLeaf
    
    run::Gtk.GtkToggleButtonLeaf
    init::Gtk.GtkButtonLeaf
    cal::Gtk.GtkCheckButtonLeaf
    
    slider::Gtk.GtkScaleLeaf
    adj::Gtk.GtkAdjustmentLeaf
    slider2::Gtk.GtkScaleLeaf
    adj2::Gtk.GtkAdjustmentLeaf
    
    c::Gtk.GtkCanvasLeaf
    c2::Gtk.GtkCanvasLeaf
    c3::Gtk.GtkCanvasLeaf
    ctx2::Cairo.CairoContext
    ctx2s::Cairo.CairoContext
    w2::Int64
    h2::Int64

    rb_active::Bool
    rb::RubberBand
    
    spike::Int64 #currently selected spike of all spikes
    num::Int64 #currently selected spike from multi display
    num16::Int64 #currently selected group of spikes in multi display
    
    scale::Array{Float64,2}
    offset::Array{Int64,1}
    
    mi::NTuple{2,Float64} #saved x,y position of mouse input
    mim::NTuple{2,Float64} #saved x,y position of mouse input on multi-channel display
    
    clus::Int64
    total_clus::Array{Int64,1}
    
    var2::Array{Int64,2} #saved variable 2 for each channel
    
    sb::Gtk.GtkSpinButtonLeaf
    
    gain::Gtk.GtkCheckButtonLeaf
    gainbox::Gtk.GtkSpinButtonLeaf
    
    draws::Int64 #how many displays have occured since the last refresh
    
    thres_all::Gtk.GtkCheckButtonLeaf
    
    events::Array{Int64,1}
    
    enabled::Array{Bool,1}
    
    show_thres::Bool
    
    time::mytime
    
    wave_points::Int64
    
    c_right_top::UInt8 #flag to indicate the drawing method to be displayed on top part of right display
    c_right_bottom::UInt8 #flag to indicate the drawing method to be displayed on the bottom part of right display
    
    popup_ed::Gtk.GtkMenuLeaf
    popup_event::Gtk.GtkMenuLeaf
    
    rb1::Array{Gtk.GtkRadioButton,1}
    rb2::Array{Gtk.GtkRadioButton,1}
    
    scope::Array{Float64,2}
    
    offbox::Gtk.GtkSpinButtonLeaf
    
    adj_thres::Gtk.GtkAdjustmentLeaf
    thres_slider::Gtk.GtkScaleLeaf
    thres_changed::Bool
    old_thres::Int64
    thres::Int64
    spike_changed::Bool
    chan_per_display::Int64

    temp::ClusterTemplate
    c_changed::Bool
    
    hold::Bool
    
    spike_buf::Array{Int16,2}
    buf_ind::Int64
    buf_count::Int64
    
    buf_button::Gtk.GtkCheckButtonLeaf
    hold_button::Gtk.GtkCheckButtonLeaf
    pause::Bool
    
    buf_clus::Array{Int64,1}
    buf_mask::Array{Bool,1}
    spike_win::Array{SpikeSorting.mywin,1}
    
    slider_sort::Gtk.GtkScaleLeaf
    adj_sort::Gtk.GtkAdjustmentLeaf
    
    sort_list::Gtk.GtkListStoreLeaf
    sort_tv::Gtk.GtkTreeViewLeaf
    
    pause_button::Gtk.GtkToggleButtonLeaf
    
    isi_ind::Int64
    isi_count::Int64
    isi_clus_ID::Array{Int64,1}
    isi_last_time::Array{UInt32,1}
    isi::Array{UInt32,1}
    isi_hist::Array{Int64,1}
    
    ref_win::Gtk.GtkWindowLeaf
    ref_tv1::Gtk.GtkTreeViewLeaf
    ref_tv2::Gtk.GtkTreeViewLeaf
    ref_list1::Gtk.GtkListStoreLeaf
    ref_list2::Gtk.GtkListStoreLeaf
    
    gain_multiply::Gtk.GtkCheckButtonLeaf
    
    sort_cb::Bool
    soft::SoftScope
    popup_scope::Gtk.GtkMenuLeaf
    
    sort_widgets::Sort_Widgets
    thres_widgets::Thres_Widgets
    gain_widgets::Gain_Widgets
    spike_widgets::Spike_Widgets
    sortview_widgets::SortView
    band_widgets::Band_Widgets
end

#=
C_Right Top Flags

1 = 16 channel
2 = 32 channels
3 = 64 channels
4 = 64 channels raster
5 = blank

C_Right Bottom Flags

1 = events/analog
2 = 16 channel raster
3 = 32 channel raster
4 = soft scope
5 = 64 channel
6 = 64 channel raster
7 = blank

=#
