
abstract Filter
abstract RHD2000
abstract Task

global num_rhd = 0

type Debug
    state::Bool
    m::ASCIIString
    data::Array{Float64,1}
    ind::Int64
    maxind::Int64
end

function gen_rhd(v,s,buf,nums)

    global num_rhd::Int64
    num_rhd+=1
    k=num_rhd
    
    @eval begin
        type $(symbol("RHD200$k")) <: RHD2000
            board::Ptr{Void}
            sampleRate::Int64
            numDataStreams::Int64
            dataStreamEnabled::Array{Int64,2}
            usbBuffer::Array{UInt8,1}
            numWords::Int64
            numBytesPerBlock::Int64
            amps::Array{Int64,1}
            v::$(typeof(v))
            s::$(typeof(s))
            time::Array{Int32,1}
            buf::$(typeof(buf))
            nums::$(typeof(nums))
            cal::Int64
            debug::Debug
            reads::Int64
            kins::Array{Float64,2}
        end

        function make_rhd(amps::Array{Int64,1},nd::Int64,v::$(typeof(v)),s::$(typeof(s)),buf::$(typeof(buf)),nums::$(typeof(nums)),debug::Debug)
            
            $(symbol("RHD200$k"))(board,30000,nd,zeros(Int64,1,MAX_NUM_DATA_STREAMS),zeros(UInt8,USB_BUFFER_SIZE),0,0,amps,v,s,zeros(Int32,10000),buf,nums,0,debug,0,zeros(Float64,10000,8))
        end
    end
end

default_sort=Algorithm[DetectSignal(),ClusterOSort(),AlignMax(),FeatureTime(),ReductionNone(),ThresholdMean()]

debug_sort=Algorithm[DetectSignal(),ClusterNone(),AlignMax(),FeatureTime(),ReductionNone(),ThresholdMean()]

default_debug=Debug(false,"off",zeros(Float64,1),0,0)

function makeRHD(amps::Array{Int64,1},sort::ASCIIString; params=default_sort, debug=default_debug)

    numchannels=length(amps)*32

    if debug.state==false
    	numDataStreams=0
    else
	numDataStreams=round(Int,numchannels/32)
        params=debug_sort
    end
      
    if sort=="single"
        v=zeros(Int64,SAMPLES_PER_DATA_BLOCK,numchannels)
        s=create_multi(params...,numchannels)
        (buf,nums)=output_buffer(numchannels)      
    elseif sort=="parallel"
        v=convert(SharedArray{Int64,2},zeros(Int64,SAMPLES_PER_DATA_BLOCK,numchannels))
        s=create_multi(params...,numchannels,true)
        (buf,nums)=output_buffer(numchannels,true)       
    end
    gen_rhd(v,s,buf,nums)
    make_rhd(amps,numDataStreams,v,s,buf,nums,debug)
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
    taps::FloatRange{Float64}
    period::Int64
    train_s::Array{Float64,2}
    train_k::Array{Float64,1}
    coeffs::Array{Float64,2}
end

function Weiner(rhd::RHD2000,ntaps::FloatRange{Float64},x::Int64,y::Int64,z::Int64)
    n=length(ntaps)
    per=ntaps.step/ntaps.divsor*rhd.sampleRate
    Weiner(ntaps,per,zeros(Float64,x,n*y+1),zeros(Float64,x,z),zeros(Float64,n*y+1,z))
end

Weiner(rhd::RHD2000,x::Int64,y::Int64,z::Int64)=Weiner(rhd,0.0:.1:0.0,x,y,z)

type Kalman <: Filter

end

type UKF <: Filter

end
