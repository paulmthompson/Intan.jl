
export SaveWave,SaveAll,SaveNone, FPGA

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

const v_save_file = "v.bin"
const ts_save_file = "ts.bin"

type SaveWave <: SaveOpt 
end

type SaveAll <: SaveOpt
end

type SaveNone <: SaveOpt
end

type FPGA
    id::Int64
    shift::Int64
    board::Ptr{Void}
    sampleRate::Int64
    numDataStreams::Int64
    dataStreamEnabled::Array{Int64,2}
    usbBuffer::Array{UInt8,1}
    numWords::Int64
    numBytesPerBlock::Int64
    amps::Array{Int64,1}
    time::Array{UInt32,1}
    adc::Array{UInt16,2}
    ttlin::Array{UInt16,1}
    ttlout::Array{UInt16,1}
end

function FPGA(board_id::Int64,amps::Array{Int64,1})
    if board_id==1
        FPGA(1,0,board,30000,0,zeros(Int64,1,MAX_NUM_DATA_STREAMS),zeros(UInt8,USB_BUFFER_SIZE),0,0,amps,zeros(UInt32,SAMPLES_PER_DATA_BLOCK),zeros(UInt16,SAMPLES_PER_DATA_BLOCK,8),zeros(UInt16,SAMPLES_PER_DATA_BLOCK),zeros(UInt16,SAMPLES_PER_DATA_BLOCK))
    elseif board_id==2
        FPGA(2,0,board2,30000,0,zeros(Int64,1,MAX_NUM_DATA_STREAMS),zeros(UInt8,USB_BUFFER_SIZE),0,0,amps,zeros(UInt32,SAMPLES_PER_DATA_BLOCK),zeros(UInt16,SAMPLES_PER_DATA_BLOCK,8),zeros(UInt16,SAMPLES_PER_DATA_BLOCK),zeros(UInt16,SAMPLES_PER_DATA_BLOCK))
    end
end

function gen_rhd(v,prev,s,buf,nums,tas,sav,filts)

    global num_rhd::Int64
    num_rhd+=1
    k=num_rhd
    
    @eval begin
        type $(symbol("RHD200$k")) <: RHD2000
            fpga::Array{FPGA,1}
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
        end

        function make_rhd(fpga::Array{FPGA,1},v::$(typeof(v)),prev::$(typeof(prev)),s::$(typeof(s)),buf::$(typeof(buf)),nums::$(typeof(nums)),debug::Debug,tas::$(typeof(tas)),sav::$(typeof(sav)),filts::$(typeof(filts)))
            
            $(symbol("RHD200$k"))(fpga,v,prev,s,buf,nums,debug,0,0,tas,sav,filts)
        end
    end
end

default_sort=Algorithm[DetectSignal(),ClusterWindow(),AlignMax(),FeatureTime(),ReductionNone(),ThresholdMean()]

debug_sort=Algorithm[DetectSignal(),ClusterWindow(),AlignMax(),FeatureTime(),ReductionNone(),ThresholdMean()]

default_debug=Debug(false,"off",zeros(Float64,1),0,0)

default_save=SaveAll()

function makeRHD(fpga::Array{FPGA,1},sort::ASCIIString,mytask::Task; params=default_sort, debug=default_debug,sav=default_sav)

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

    notches=[make_notch(59,61,30000) for i=1:numchannels]
    
    if sort=="single"
        v=zeros(Int16,SAMPLES_PER_DATA_BLOCK,numchannels)
        prev=zeros(Float64,SAMPLES_PER_DATA_BLOCK)
        s=create_multi(params...,numchannels)
        (buf,nums)=output_buffer(numchannels)      
    elseif sort=="parallel"
        v=convert(SharedArray{Int16,2},zeros(Int64,SAMPLES_PER_DATA_BLOCK,numchannels))
        prev=convert(SharedArray{Float64,1},zeros(Int64,SAMPLES_PER_DATA_BLOCK))
        s=create_multi(params...,numchannels,1:1)
        (buf,nums)=output_buffer(numchannels,true)       
    end
    gen_rhd(v,prev,s,buf,nums,mytask,sav,notches)
    make_rhd(fpga,v,prev,s,buf,nums,debug,mytask,sav,notches)
end

function make_notch(wn1,wn2,sr)
    responsetype = Bandstop(wn1,wn2; fs=sr)
    designmethod = Butterworth(4)
    df1=digitalfilter(responsetype, designmethod)
    DF2TFilter(df1)
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
    spike::Int64 #currently selected spike out of total
    num::Int64 #currently selected spike out of 16
    num16::Int64 #currently selected 16 channels
    scale::Array{Float64,2}
    offset::Array{Float64,2}
    mi::NTuple{2,Float64} #saved x,y position of mouse input
    var1::Array{Int64,2} #saved variable 1 for each channel
    var2::Array{Int64,2} #saved variable 2 for each channel
    sb::Gtk.GtkSpinButtonLeaf
    tb1::Gtk.GtkLabelLeaf
    tb2::Gtk.GtkLabelLeaf
    gain::Gtk.GtkCheckButtonLeaf
    gainbox::Gtk.GtkSpinButtonLeaf
    draws::Int64
    thres_all::Gtk.GtkCheckButtonLeaf
end
