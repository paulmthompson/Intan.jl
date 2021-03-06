
export FPGA

abstract type RHD2000 end
abstract type Task end
abstract type IC end

mutable struct Debug
    state::Bool
    m::String
    filepath::String
    data::Array{Float64,1}
    ind::Int64
    maxind::Int64
    delay::Bool
    delay_t::Float64
end

mutable struct Intan_Filter
    chan::Int64
    output::Int64
    wn1::Int64
    wn2::Int64
    f_type::Int64
    filt::MyFilter
end

mutable struct SaveOpt
    record_mode::Bool
    save_full::Bool
    v::String

    ts_s::Bool
    ts::String

    adc_s::Bool
    adc::String

    #Intan board ttls
    ttl_s::Bool
    ttl::String
    ttl_out::String

    #Local field potential could be saved if it is calculated in real time
    lfp_s::Bool
    lfp::String

    #Location for saved files
    folder::String
    backup::String
end

function make_save_structure(save_full::Bool)
    @static if is_unix()
        t=string("./",now())
        out=SaveOpt(false,save_full,string(t,"/v.bin"),false,string(t,"/ts.bin"),false,string(t,"/adc.bin"),false,string(t,"/ttl.bin"),string(t,"/ttl_out.bin"),false,string(t,"/lfp.bin"),t,string(t,"/.backup/"))
    end

    @static if is_windows()
        t=Dates.format(now(),"yyyy-mm-dd-HH-MM-SS")
        out=SaveOpt(false,save_full,string(t,"\\v.bin"),false,string(t,"\\ts.bin"),false,string(t,"\\adc.bin"),false,string(t,"\\ttl.bin"),string(t,"\\ttl_out.bin"),false,string(t,"\\lfp.bin"),t,string(t,"\\.backup\\"))
    end
    out
end

mutable struct register
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

mutable struct DigOut
    channel::Int32

    pulseOrTrain::Int32 #0 = single Pulse, 1 = pulse train

    triggerEnabled::Bool
    triggerOnLow::Bool # 0 = High Trigger, 1 = Low trigger
    edgeTriggered::Bool # 0 = edge, 1 = Level triggered
    triggerSource::Int32 #0 - 15 corresponds to digital in 1 through 16, 16-23 is analog inputs, 24 through 31 is keypresses

    shapeInt::Int32 # 0 = Biphasic, 1 = Biphasic with delay, 2 = Triphasic, 3 = monophasic
    negStimFirst::Bool # 0 = negative first, 1 = positive first
    numPulses::Int32

    postTriggerDelay::Int32 #after trigger, before pulse
    firstPhaseDuration::Int32
    refractoryPeriod::Int32
    pulseTrainPeriod::Int32

    repeatBurst::Bool
end

function DigOut()
    DigOut(0,0,false,false,false,0,3,false,1,0,1000,5000,5000,false)
end

mutable struct FPGA <: IC
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
    adc::Array{Int16,2}
    ttlin::Array{UInt16,1}
    ttlout::Array{UInt16,1}
    ttloutput::UInt16
    usb3::Bool
    r::register
    d::Array{DigOut,1}
end

function FPGA(board_id::Int64,amps::Array{Int64,1};usb3=false)
    board = Ptr{Void}(1)
    mylib = Ptr{Void}(1)
    if board_id==1
        FPGA(1,board,mylib,0,30000,0,zeros(Int64,1,MAX_NUM_DATA_STREAMS),zeros(UInt8,USB_BUFFER_SIZE),0,0,amps,zeros(Int16,SAMPLES_PER_DATA_BLOCK,8),zeros(UInt16,SAMPLES_PER_DATA_BLOCK),zeros(UInt16,SAMPLES_PER_DATA_BLOCK),0,usb3,CreateRHD2000Registers(30000),[DigOut() for i=1:16])
    elseif board_id==2
        FPGA(2,board,mylib,0,30000,0,zeros(Int64,1,MAX_NUM_DATA_STREAMS),zeros(UInt8,USB_BUFFER_SIZE),0,0,amps,zeros(Int16,SAMPLES_PER_DATA_BLOCK,8),zeros(UInt16,SAMPLES_PER_DATA_BLOCK),zeros(UInt16,SAMPLES_PER_DATA_BLOCK),0,usb3,CreateRHD2000Registers(30000),[DigOut() for i=1:16])
    end
end

mutable struct RHD_Single <: RHD2000
    v::Array{Int16,2}
    buf::Array{Spike,2}
    nums::Array{UInt16,1}
    debug::Debug
    reads::Int64
    cal::Int64
    save::SaveOpt
    sr::Int64
    refs::Array{Int64,1}
    ttl_state::Bool
    time::Array{UInt32,2}
    filts::Array{Array{Intan_Filter,1},1}
    lfps::Array{Int16,2}
    initialized::Bool
end

function RHD_Single(fpga,num_channels,s,buf,nums,debug)
    if VERSION > v"0.7-"
        the_filters = [Array{Intan_Filter}(undef, 0) for i=1:num_channels]
    else
        the_filters = [Array{Intan_Filter}(0) for i=1:num_channels]
    end
    RHD_Single(zeros(Int16,SAMPLES_PER_DATA_BLOCK,num_channels),buf,nums,debug,0,0,make_save_structure(false),30000,zeros(Int64,num_channels),false,zeros(UInt32,SAMPLES_PER_DATA_BLOCK,length(fpga)),the_filters,zeros(Int16,SAMPLES_PER_DATA_BLOCK,num_channels),false)
end

mutable struct RHD_Parallel <: RHD2000
    v::SharedArray{Int16,2}
    buf::SharedArray{Spike,2}
    nums::SharedArray{UInt16,1}
    debug::Debug
    reads::Int64
    cal::Int64
    save::SaveOpt
    sr::Int64
    refs::Array{Int64,1}
    ttl_state::Bool
    time::SharedArray{UInt32,2}
    filts::Array{Array{Intan_Filter,1},1}
    lfps::SharedArray{Int16,2}
    initialized::Bool
end

function RHD_Parallel(fpga,num_channels,s,buf,nums,debug)
    if VERSION > v"0.7-"
        the_filters = [Array{Intan_Filter}(undef, 0) for i=1:num_channels]
    else
        the_filters = [Array{Intan_Filter}(0) for i=1:num_channels]
    end
    RHD_Parallel(convert(SharedArray{Int16,2},zeros(Int16,SAMPLES_PER_DATA_BLOCK,num_channels)),buf,nums,debug,0,0,make_save_structure(false),30000,zeros(Int64,num_channels),false,convert(SharedArray{UInt32,2},zeros(UInt32,SAMPLES_PER_DATA_BLOCK,length(fpga))),the_filters,zeros(Int16,SAMPLES_PER_DATA_BLOCK,num_channels),false)
end

default_sort=Algorithm[DetectNeg(),ClusterTemplate(49),AlignMin(),FeatureTime(),ReductionNone(),ThresholdMeanN()]

debug_sort=Algorithm[DetectNeg(),ClusterTemplate(49),AlignProm(),FeatureTime(),ReductionNone(),ThresholdMeanN()]

default_debug=Debug(false,"off","",zeros(Float64,1),0,0,false,0.0)

function makeRHD(fpga::Array{FPGA,1}; params=default_sort, parallel=false, debug=default_debug,
    sr=30000,wave_time=1.6,single_channel_mode=false,emg=false)

    c_per_fpga=[length(fpga[i].amps)*32 for i=1:length(fpga)]

    if length(c_per_fpga)>1
        for i=2:length(c_per_fpga)
            fpga[i].shift=c_per_fpga[i-1]
        end
    end

    numchannels=sum(c_per_fpga)

    #Single Channel
    if single_channel_mode
        numchannels=1
        fpga[1].amps[1]=255
    end

    if debug.state==true
        params=debug_sort
    end

    wave_points=get_wavelength(sr,wave_time)

    if parallel==false
        s=create_multi(params...,numchannels,wave_points)
        (buf,nums)=output_buffer(numchannels)
        fpgas=fpga
        rhd=RHD_Single(fpgas,numchannels,s,buf,nums,debug)
    else
        s=create_multi(params...,numchannels,workers()[1]:workers()[end],wave_points)
        (buf,nums)=output_buffer(numchannels,true)
        fpgas=distribute(fpga)
        rhd=RHD_Parallel(fpgas,numchannels,s,buf,nums,debug)
    end

    rhd.sr=sr

    (rhd,s,fpgas)
end

get_wavelength(sr,timewin)=round(Int,sr*timewin/1000)

mutable struct mytime
    h::Int8
    h_l::Gtk.GtkLabelLeaf
    m::Int8
    m_l::Gtk.GtkLabelLeaf
    s::Int8
    s_l::Gtk.GtkLabelLeaf
end

mutable struct SoftScope
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
    signal_type::Int64
    ctx::Cairo.CairoContext
end

function SoftScope(sr,ctx,sz)
    SoftScope(zeros(Float64,sz*10),1,zeros(Float64,sz),1.0/1000,1.0,1,zeros(Int64,500),0,zeros(Int64,500),0,false,1,ctx)
end

mutable struct Spectrogram
    f_max::Int64
    t_max::Int64
    win_width_t::Float64
    win_overlap_t::Float64
    win_width_s::Int64
    win_overlap_s::Int64
    out::Array{Float64,2}
    f_div::Float64
    t_div::Float64
    fs::Int64
end

function Spectrogram(fs; win_width_t = .01,win_overlap_t = .002, f_max = 15000)

    win_width_s=convert(Int, win_width_t*fs)
    win_overlap_s=convert(Int, win_overlap_t*fs)

    S = spectrogram(rand(Float64,fs),win_width_s,win_overlap_s; fs=fs, window=hanning)
    P = power(S)

    f_div=freq(S).multiplier
    t_div=time(S).step

    f_max = ceil(Int64,f_max / f_div)

    f_max = (f_max > size(P,1)) ? size(P,1) : f_max
    t_max = size(P,2)

    out=zeros(Float64,f_max,t_max)

    Spectrogram(f_max,t_max,win_width_t,win_overlap_t,win_width_s,win_overlap_s,out,f_div,t_div,fs)
end

mutable struct Band_Widgets
    win::Gtk.GtkWindowLeaf
    sb1::Gtk.GtkSpinButtonLeaf #Hardware Low Cut
    sb2::Gtk.GtkSpinButtonLeaf #Hardware High Cut
    sb3::Gtk.GtkSpinButtonLeaf #Hardware DSP High Pass
    b1::Gtk.GtkButtonLeaf #Button to update Headstage Hardware Filters
    sw_box::Gtk.GtkComboBoxTextLeaf
    wn_sb1::Gtk.GtkSpinButtonLeaf #Software Filter Bandwidth Low
    wn_sb2::Gtk.GtkSpinButtonLeaf #Software Filter Bandwidth High

    sw_chan_sb::Gtk.GtkSpinButtonLeaf #channel number to apply software filter to

    add_b::Gtk.GtkButtonLeaf #Add software filter
    re_b::Gtk.GtkButtonLeaf #Replace software Filter
    delete_b::Gtk.GtkButtonLeaf

    sw_check::Gtk.GtkCheckButtonLeaf #Apply filter to all channels

    wn_sb1_l::Gtk.GtkLabelLeaf
    wn_sb2_l::Gtk.GtkLabelLeaf

    output_box::Gtk.GtkComboBoxTextLeaf
    filt_num_sb::Gtk.GtkSpinButtonLeaf #filter number
    c::Gtk.GtkCanvasLeaf

    wn1::Int64
    wn2::Int64
    f_type::Int64
    f_pos::Int64
    f_out::Int64
    chan::Int64
    lfp_en::Array{Bool,1}

    tv::Gtk.GtkTreeViewLeaf
    list::Gtk.GtkListStoreLeaf
end

mutable struct Sort_Widgets
    b1::Gtk.GtkButtonLeaf
    b2::Gtk.GtkButtonLeaf
    b3::Gtk.GtkButtonLeaf
    b4::Gtk.GtkToggleButtonLeaf
    check::Gtk.GtkCheckButtonLeaf
    slider_active::Bool
end

mutable struct Spike_Widgets
    refresh::Gtk.GtkButtonLeaf
    pause::Gtk.GtkToggleButtonLeaf
end

mutable struct Table_Widgets
    win::Gtk.GtkWindowLeaf
    tv::Gtk.GtkTreeViewLeaf
    list::Gtk.GtkListStoreLeaf
    gain_text::Gtk.GtkCellRendererText
    thres_text::Gtk.GtkCellRendererText
    ref_text::Gtk.GtkCellRendererText
    enabled_toggle::Gtk.GtkCellRendererToggle
end

mutable struct Save_Widgets
    win::Gtk.GtkWindowLeaf
    volt::Gtk.GtkCheckButtonLeaf
    lfp::Gtk.GtkCheckButtonLeaf
    ttlin::Gtk.GtkCheckButtonLeaf
    ts::Gtk.GtkCheckButtonLeaf
    adc::Gtk.GtkCheckButtonLeaf
    input::Gtk.GtkEntryLeaf
end

mutable struct Reference_Widgets
    win::Gtk.GtkWindowLeaf
    tv1::Gtk.GtkTreeViewLeaf
    tv2::Gtk.GtkTreeViewLeaf
    list1::Gtk.GtkListStoreLeaf
    list2::Gtk.GtkListStoreLeaf
    select_button::Gtk.GtkButtonLeaf
    apply_button::Gtk.GtkButtonLeaf
end

mutable struct Gui_Handles
    win::Gtk.GtkWindowLeaf

    run::Gtk.GtkToggleButtonLeaf
    init::Gtk.GtkButtonLeaf
    #cal::Gtk.GtkCheckButtonLeaf
    record::Gtk.GtkToggleButtonLeaf

    slider::Gtk.GtkScaleLeaf
    adj::Gtk.GtkAdjustmentLeaf
    slider2::Gtk.GtkScaleLeaf
    adj2::Gtk.GtkAdjustmentLeaf

    c::Gtk.GtkCanvasLeaf

    num::Int64 #currently selected spike from multi display
    num16::Int64 #currently selected group of spikes in multi display

    scale::Array{Float64,2}
    offset::Array{Int64,1}

    mim::NTuple{2,Float64} #saved x,y position of mouse input on multi-channel display

    total_clus::Array{Int64,1}

    draws::Int64 #how many displays have occured since the last refresh

    events::Array{Int64,1}

    enabled::Array{Bool,1}

    time::mytime

    wave_points::Int64

    c_right_top::UInt8 #flag to indicate the drawing method to be displayed on top part of right display
    c_right_bottom::UInt8 #flag to indicate the drawing method to be displayed on the bottom part of right display

    popup_ed::Gtk.GtkMenuLeaf
    popup_event::Gtk.GtkMenuLeaf
    popup_spect::Gtk.GtkMenuLeaf

    rb1::Array{Gtk.GtkRadioButton,1}
    rb2::Array{Gtk.GtkRadioButton,1}

    scope::Array{Float64,2}

    spike_changed::Bool
    chan_per_display::Int64

    c_changed::Bool

    slider_sort::Gtk.GtkScaleLeaf

    isi_ind::Int64
    isi_count::Int64
    isi_clus_ID::Array{Int64,1}
    isi_last_time::Array{UInt32,1}
    isi::Array{UInt32,1}
    isi_hist::Array{Int64,1}

    soft::SoftScope
    popup_scope::Gtk.GtkMenuLeaf

    sort_widgets::Sort_Widgets
    spike_widgets::Spike_Widgets
    sortview_widgets::SortView
    band_widgets::Band_Widgets
    table_widgets::Table_Widgets
    spect::Spectrogram
    save_widgets::Save_Widgets
    ref_widgets::Reference_Widgets
    b::Gtk.GtkBuilder

    sc::SpikeSorting.Single_Channel

    buf::SpikeSorting.Buffer

    v_s::Array{Int16,1}
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
