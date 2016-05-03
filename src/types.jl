
export SaveWave,SaveAll,SaveNone

abstract RHD2000
abstract Task
abstract SaveOpt

global num_rhd = 0

type Debug
    state::Bool
    m::ASCIIString
    data::Array{Float64,1}
    ind::Int64
    maxind::Int64
end

type SaveWave <: SaveOpt 
end

type SaveAll <: SaveOpt
end

type SaveNone <: SaveOpt
end

function gen_rhd(v,s,buf,nums,tas,sav)

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
            time::Array{UInt32,1}
            buf::$(typeof(buf))
            nums::$(typeof(nums))
            cal::Int64
            debug::Debug
            reads::Int64
            task::$(typeof(tas))
            save::$(typeof(sav))
            adc::Array{UInt16,2}
            ttlin::Array{UInt16,1}
            ttlout::Array{UInt16,1}
        end

        function make_rhd(amps::Array{Int64,1},v::$(typeof(v)),s::$(typeof(s)),buf::$(typeof(buf)),nums::$(typeof(nums)),debug::Debug,tas::$(typeof(tas)),sav::$(typeof(sav)))
            
            $(symbol("RHD200$k"))(board,30000,0,zeros(Int64,1,MAX_NUM_DATA_STREAMS),zeros(UInt8,USB_BUFFER_SIZE),0,0,amps,v,s,zeros(UInt32,SAMPLES_PER_DATA_BLOCK),buf,nums,0,debug,0,tas,sav,zeros(UInt16,SAMPLES_PER_DATA_BLOCK,8),zeros(UInt16,SAMPLES_PER_DATA_BLOCK),zeros(UInt16,SAMPLES_PER_DATA_BLOCK))
        end
    end
end

default_sort=Algorithm[DetectSignal(),ClusterWindow(),AlignMax(),FeatureTime(),ReductionNone(),ThresholdMean()]

debug_sort=Algorithm[DetectSignal(),ClusterWindow(),AlignMax(),FeatureTime(),ReductionNone(),ThresholdMean()]

default_debug=Debug(false,"off",zeros(Float64,1),0,0)

default_save=SaveAll()

function makeRHD(amps::Array{Int64,1},sort::ASCIIString,mytask::Task; params=default_sort, debug=default_debug,sav=default_sav)

    numchannels=length(amps)*32
    if debug.state==true
        params=debug_sort
    end
      
    if sort=="single"
        v=zeros(Int16,SAMPLES_PER_DATA_BLOCK,numchannels)
        s=create_multi(params...,numchannels)
        (buf,nums)=output_buffer(numchannels)      
    elseif sort=="parallel"
        v=convert(SharedArray{Int16,2},zeros(Int64,SAMPLES_PER_DATA_BLOCK,numchannels))
        s=create_multi(params...,numchannels,1:1)
        (buf,nums)=output_buffer(numchannels,true)       
    end
    gen_rhd(v,s,buf,nums,mytask,sav)
    make_rhd(amps,v,s,buf,nums,debug,mytask,sav)
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
    mi::NTuple{2,Float64} #saved x,y position of mouse input
    var1::Array{Int64,2} #saved variable 1 for each channel
    var2::Array{Int64,2} #saved variable 2 for each channel
end
