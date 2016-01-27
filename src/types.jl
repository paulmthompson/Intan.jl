
abstract Amp
abstract Filter

type RHD2164 <: Amp
    port::Array{Int64,1}
end

function RHD2164(port::ASCIIString)
    if port=="PortA1"
        ports=[PortA1,PortA1Ddr]
    elseif port=="PortA2"
        ports=[PortA2,PortA2Ddr]
    elseif port=="PortB1"
        ports=[PortB1,PortB1Ddr]
    elseif port=="PortB2"
        ports=[PortB2,PortB2Ddr]
    elseif port=="PortC1"
        ports=[PortC1,PortC1Ddr]
    elseif port=="PortC2"
        ports=[PortC2,PortC2Ddr]
    elseif port=="PortD1"
        ports=[PortD1,PortD1Ddr]
    elseif port=="PortD2"
        ports=[PortD2,PortD2Ddr]
    else
        ports=[0,0]
    end

    RHD2164(ports) 
end

type RHD2132 <: Amp
    port::Array{Int64,1}
end

function RHD2132(port::ASCIIString)
    if port=="PortA1"
        ports=[PortA1]
    elseif port=="PortA2"
        ports=[PortA2]
    elseif port=="PortB1"
        ports=[PortB1]
    elseif port=="PortB2"
        ports=[PortB2]
    elseif port=="PortC1"
        ports=[PortC1]
    elseif port=="PortC2"
        ports=[PortC2]
    elseif port=="PortD1"
        ports=[PortD1]
    elseif port=="PortD2"
        ports=[PortD2]
    else
        ports=[0]
    end

    RHD2132(ports)
end

type Debug
    state::Bool
    m::ASCIIString
    data::Array{Float64,1}
    ind::Int64
    maxind::Int64
end

type RHD2000{T<:Amp,U,V<:AbstractArray{Int64,2},W<:AbstractArray{Spike,2},X<:AbstractArray{Int64,1}}
    board::Ptr{Void}
    sampleRate::Int64
    numDataStreams::Int64
    dataStreamEnabled::Array{Int64,2}
    usbBuffer::Array{UInt8,1}
    numWords::Int64
    numBytesPerBlock::Int64
    amps::Array{T,1}
    v::V
    s::U
    time::Array{Int32,1}
    buf::W
    nums::X
    cal::Int64
    debug::Debug
    reads::Int64
end

default_sort=Algorithm[DetectPower(),ClusterOSort(),AlignMax(),FeatureTime(),ReductionNone(),ThresholdMean()]

debug_sort=Algorithm[DetectPower(),ClusterNone(),AlignMax(),FeatureTime(),ReductionNone(),ThresholdMean()]

default_debug=Debug(false,"off",zeros(Float64,1),0,0)

function RHD2000{T<:Amp}(amps::Array{T,1},sort::ASCIIString; params=default_sort, debug=default_debug)

    numchannels=0

    for i=1:length(amps)
        if typeof(amps[i])==RHD2164
            numchannels+=64
        elseif typeof(amps[i])==2132
            numchannels+=32
        end
    end

    sampleRate=30000 #default

    if debug.state==false
    	numDataStreams=0
    else
	numDataStreams=round(Int,numchannels/32)
        params=debug_sort
    end

    dataStreamEnabled=zeros(Int64,1,MAX_NUM_DATA_STREAMS)

    usbBuffer = zeros(UInt8,USB_BUFFER_SIZE)

    numWords = 0

    numBytesPerBlock = 0

    mytime=zeros(Int32,10000)
    
    if sort=="single"
        v=zeros(Int64,SAMPLES_PER_DATA_BLOCK,numchannels)
        s=create_multi(params...,numchannels)
        (buf,nums)=output_buffer(numchannels)
        RHD2000(board,sampleRate,numDataStreams,dataStreamEnabled,usbBuffer,numWords,numBytesPerBlock,amps,v,s,mytime,buf,nums,0,debug,0)
    elseif sort=="parallel"
        v=convert(SharedArray{Int64,2},zeros(Int64,SAMPLES_PER_DATA_BLOCK,numchannels))
        s=create_multi(params...,numchannels,true)
        (buf,nums)=output_buffer(numchannels,true)
        RHD2000(board,sampleRate,numDataStreams,dataStreamEnabled,usbBuffer,numWords,numBytesPerBlock,amps,v,s,mytime,buf,nums,0,debug,0)
    else
        v=zeros(Int64,SAMPLES_PER_DATA_BLOCK,numchannels)
        s=create_multi(params...,numchannels)
        (buf,nums)=output_buffer(numchannels)
        RHD2000(board,sampleRate,numDataStreams,dataStreamEnabled,usbBuffer,numWords,numBytesPerBlock,amps,v,s,mytime,buf,nums,0,debug,0)
    end

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
    slider3::Gtk.GtkScaleLeaf
    adj3::Gtk.GtkAdjustmentLeaf
    spike::Int64 #currently selected spike out of total
    num::Int64 #currently selected spike out of 16
    num16::Int64 #currently selected 16 channels
    scale::Array{Float64,2}
    offset::Array{Float64,2}
end

type Weiner <: Filter
    train_s::Array{Array{Int64,1},1}
    train_k::Array{Float64,1}
    coeffs::Array{Float64,2}
end

type Kalman <: Filter

end

type UKF <: Filter

end
