
export save_ts_jld, save_ts_mat, parse_v
#=
methods to select which variables in workspace to save
=#

type Voltage_Header
    date_m::UInt8
    date_d::UInt8
    date_y::UInt16
    time_h::UInt8
    time_m::UInt8
    num_channels::UInt16
    samples_per_block::UInt16
end

Voltage_Header()=Voltage_Header(0,0,0,0,0,0,0)

function read_v_header(fname="v.bin")

    f=open(fname,"r+")

    myheader=Voltage_Header()
    
    myheader.date_m=read(f,UInt8,1)[1]
    myheader.date_d=read(f,UInt8,1)[1]
    myheader.date_y=read(f,UInt16,1)[1]
    myheader.time_h=read(f,UInt8,1)[1]
    myheader.time_m=read(f,UInt8,1)[1]
    myheader.num_channels=read(f,UInt16,1)[1]
    myheader.samples_per_block=read(f,UInt16,1)[1]

    close(f)

    myheader
end

function prepare_v_header(rhd::RHD2000)

    f=open(rhd.save.v,"a+")

    t=now()
    
    write(f,convert(UInt8,Dates.month(t)))
    write(f,convert(UInt8,Dates.day(t)))
    write(f,convert(UInt16,Dates.year(t)))
    write(f,convert(UInt8,Dates.hour(t)))
    write(f,convert(UInt8,Dates.minute(t)))
    write(f,convert(UInt16,size(rhd.v,2)))
    write(f,convert(UInt16,size(rhd.v,1)))

    close(f)

    nothing
end

type Stamp_Header
    date_m::UInt8
    date_d::UInt8
    date_y::UInt16
    time_h::UInt8
    time_m::UInt8
    num_channels::UInt16
    sr::UInt32
end

Stamp_Header()=Stamp_Header(0,0,0,0,0,0,0)

function read_stamp_header(fname="ts.bin")

    f=open(fname,"r+")

    myheader=Stamp_Header()
    
    myheader.date_m=read(f,UInt8,1)[1]
    myheader.date_d=read(f,UInt8,1)[1]
    myheader.date_y=read(f,UInt16,1)[1]
    myheader.time_h=read(f,UInt8,1)[1]
    myheader.time_m=read(f,UInt8,1)[1]
    myheader.num_channels=read(f,UInt16,1)[1]
    myheader.sr=read(f,UInt32,1)[1]

    close(f)

    myheader    
end

function prepare_stamp_header(rhd::RHD2000)

    f=open(rhd.save.ts,"a+")

    t=now()
    
    write(f,convert(UInt8,Dates.month(t)))
    write(f,convert(UInt8,Dates.day(t)))
    write(f,convert(UInt16,Dates.year(t)))
    write(f,convert(UInt8,Dates.hour(t)))
    write(f,convert(UInt8,Dates.minute(t)))
    write(f,convert(UInt16,size(rhd.v,2)))
    write(f,convert(UInt32,rhd.sr))

    close(f)

    nothing
end
    
type ADC_Header
    date_m::UInt8
    date_d::UInt8
    date_y::UInt16
    time_h::UInt8
    time_m::UInt8
    num_channels::UInt16
    samples_per_block::UInt16
end

ADC_Header()=ADC_Header(0,0,0,0,0,0,0)

function read_adc_header(fname="adc.bin")

    f=open(fname,"r+")

    myheader=ADC_Header()
    
    myheader.date_m=read(f,UInt8,1)[1]
    myheader.date_d=read(f,UInt8,1)[1]
    myheader.date_y=read(f,UInt16,1)[1]
    myheader.time_h=read(f,UInt8,1)[1]
    myheader.time_m=read(f,UInt8,1)[1]
    myheader.num_channels=read(f,UInt16,1)[1]
    myheader.samples_per_block=read(f,UInt16,1)[1]

    close(f)

    myheader   
end

function prepare_adc_header(rhd::RHD2000)

    f=open(rhd.save.adc,"a+")

    t=now()

    write(f,convert(UInt8,Dates.month(t)))
    write(f,convert(UInt8,Dates.day(t)))
    write(f,convert(UInt16,Dates.year(t)))
    write(f,convert(UInt8,Dates.hour(t)))
    write(f,convert(UInt8,Dates.minute(t)))
    write(f,convert(UInt16,size(rhd.v,2)))
    write(f,convert(UInt16,size(rhd.v,1)))

    close(f)

    nothing
end

type TTL_Header
    date_m::UInt8
    date_d::UInt8
    date_y::UInt16
    time_h::UInt8
    time_m::UInt8
    num_channels::UInt16
    samples_per_block::UInt16
    sr::UInt32
end

TTL_Header()=TTL_Header(0,0,0,0,0,0,0,0)

function read_ttl_header(fname="ttl.bin")

    f=open(fname,"r+")

    myheader=ADC_Header()
    
    myheader.date_m=read(f,UInt8,1)[1]
    myheader.date_d=read(f,UInt8,1)[1]
    myheader.date_y=read(f,UInt16,1)[1]
    myheader.time_h=read(f,UInt8,1)[1]
    myheader.time_m=read(f,UInt8,1)[1]
    myheader.num_channels=read(f,UInt16,1)[1]
    myheader.samples_per_block=read(f,UInt16,1)[1]
    myheader.sr=read(f,UInt32,1)[1]

    close(f)

    myheader 
end

function prepare_ttl_header(rhd::RHD2000)

    f=open(rhd.save.ttl,"a+")

    t=now()

    write(f,convert(UInt8,Dates.month(t)))
    write(f,convert(UInt8,Dates.day(t)))
    write(f,convert(UInt16,Dates.year(t)))
    write(f,convert(UInt8,Dates.hour(t)))
    write(f,convert(UInt8,Dates.minute(t)))
    write(f,convert(UInt16,16))
    write(f,convert(UInt16,size(rhd.v,1)))
    write(f,convert(UInt32,rhd.sr))

    close(f)
    
    nothing
end

#=
Voltage
=#

function parse_v(fname="v.bin")

    myheader=read_v_header(fname)

    f=open(fname, "r+")

    seekend(f)
    l=position(f)-10
    v=zeros(Int16,div(l,2*myheader.num_channels),myheader.num_channels)

    seek(f,10)

    count=0
    while eof(f)==false
        for i=1:myheader.num_channels
            for j=1:myheader.samples_per_block
                v[count+j,i]=read(f,Int16)
            end
        end
        count+=myheader.samples_per_block
    end
    close(f)
    
    v
end

function save_v_mat(in_name="v.bin",out_name="v.mat")

    v=parse_v(in_name)

    file = matopen(out_name, "w")
    write(file, "v", v)
    close(file)
      
    nothing
end

function save_v_jld(in_name="v.bin",out_name="v.jld")

    v=parse_v(in_name)

    file = jldopen(out_name, "w")
    write(file, "v", v)
    close(file)
    
    nothing
end

#=
Time Stamps
=#

function parse_ts(fname="ts.bin")

    myheader=read_stamp_header(fname)

    ss=[Array(Spike,0) for i=1:myheader.num_channels]
    
    numcells=zeros(Int64,myheader.num_channels)

    f=open(fname, "r+")

    seek(f,12)

    while eof(f)==false

        t=read(f,UInt32,1)[1]

        for j=1:myheader.num_channels
            chan=read(f,UInt16,1)[1] #channel
            num=read(f,UInt16,1)[1] #Number of upcoming spikes
            for i=1:num
                myss=read(f,Int64,2) #time stamps
                clus=read(f,UInt8,1)[1] #cluster
                if clus>numcells[j]
                    numcells[j]=clus
                end
                push!(ss[j],Spike((t+myss[1]:t+myss[2]),clus))
            end
        end
    
    end

    close(f)

    (ss,numcells)
end

function get_ts_dict(ss::Array{Array{Spike,1},1},numcells::Array{Int64,1},sr=30000,tmin=0.0)

    spikes=Dict{String,Array{Float64,1}}()

    for i=1:length(numcells)
        for j=1:numcells[i]
            myname=string("s",i,"_",j)
            
            myspikes=zeros(Float64,0)
            
            for k=1:length(ss[i])
                if (ss[i][k].inds.start/sr>tmin) &&(ss[i][k].id==j)
                    push!(myspikes,ss[i][k].inds.start/sr)
                end             
            end   
            spikes[myname]=myspikes
        end
    end
    spikes
end

function save_ts_mat(in_name="ts.bin",out_name="ts.mat")

    myheader=read_stamp_header(in_name)

    (ss,numcells)=parse_ts(in_name)
    
    spikes=get_ts_dict(ss,numcells,myheader.sr)
    
    file = matopen(out_name, "w")
    write(file, "spikes", spikes)
    close(file)
      
    spikes   
end

function save_ts_jld(in_name="ts.bin",out_name="ts.jld")

    myheader=read_stamp_header(in_name)

    (ss,numcells)=parse_ts(in_name)
    
    spikes=get_ts_dict(ss,numcells,myheader.sr)
    
    file = jldopen(out_name, "w")
    write(file, "spikes", spikes)
    close(file)
      
    spikes 
end

#=
ADC Signals
=#

function parse_adc(fname="adc.bin")

    myheader=read_adc_header(fname)

    f=open(fname, "r+")

    seekend(f)
    l=position(f)-10
    adc=zeros(UInt16,div(l,2*myheader.num_channels),myheader.num_channels)

    seek(f,10)

    count=0
    while eof(f)==false
        for i=1:myheader.num_channels
            for j=1:myheader.samples_per_block
                adc[count+j,i]=read(f,UInt16)
            end
        end
        count+=myheader.samples_per_block
    end
    close(f)
    
    adc
end

#=
Events
=#

function parse_ttl(fname="ttl.bin")

    myheader=read_ttl_header(fname)

    ttl_times=[zeros(Float64,0) for i=1:myheader.num_channels]
    
    f=open(fname, "r+")

    seek(f,14) #start at second time step

    x_p=read(f,UInt16)

    count=2
    while eof(f)==false

        x=read(f,UInt16)
        
        for i=1:myheader.num_channels
            y=x&(2^(i-1))
            if y>0
                y_p=x_p&(2^(i-1))
                if y_p==0
                    push!(ttl_times[i],count/myheader.sr)
                end
            end
        end
        x_p=x
        count+=1
    end
    close(f)
    
    ttl_times
end

#=
EXPORT TO PLEXON

Methods to convert data waveforms to PLX so it can be used with offline sorter.
Thanks to Simon Kornblith for linking to description of PLX data structures here:
http://hardcarve.com/wikipic/PlexonDataFileStructureDocumentation.pdf
=#

type PL_FileHeader
	MagicNumber::UInt32
	Version::Int32
    	Comment::Array{UInt8,1}
	ADFrequency::Int32
	NumDSPChannels::Int32
	NumEventChannels::Int32
	NumSlowChannels::Int32
	NumPointsWave::Int32
	NumPointsPreThr::Int32
	Year::Int32
	Month::Int32
	Day::Int32
	Hour::Int32
	Minute::Int32
	Second::Int32
	FastRead::Int32
	WaveformFreq::Int32
	LastTimestamp::Float64
	Trodalness::UInt8
	DataTrodalness::UInt8
	BitsPerSpikeSample::UInt8
	BitsPerSlowSample::UInt8
	SpikeMaxMagnitudeMV::UInt16
	SlowMaxMagnitudeMV::UInt16
	SpikePreAmpGain::UInt16
    	Padding::Array{UInt8,1}
    	TSCounts::Array{Int32,2}
    	WFCounts::Array{Int32,2}
    	EVCounts::Array{Int32,1}
end

function PL_FileHeader(sr,num_chan,num_point,pre_t,t_end,tscounts)
    mn=0x58454c50
    ver=105
    com=zeros(UInt8,128)
    pad=zeros(UInt8,46)
    evcounts=zeros(Int32,512)

    PL_FileHeader(mn,ver,com,sr,num_chan,0,0,num_point,pre_t,1,1,1,1,1,1,0,0,t_end,0x01,0x01,16,12,3000,5000,0x03e8,pad,tscounts,tscounts,evcounts)
end

type PL_ChanHeader
    	Name::Array{UInt8,1}
    	SIGName::Array{UInt8,1}
	Channel::Int32
	WFRate::Int32
	SIG::Int32
	Ref::Int32
	Gain::Int32
	Filter::Int32
	Threshold::Int32
	Method::Int32
	NUnits::Int32
    	Template::Array{Int16,2}
    	Fit::Array{Int32,1}
	SortWidth::Int32
    	Boxes::Array{Int16,3}
	SortBeg::Int32
    	Comment::Array{UInt8,1}
    	Padding::Array{Int32,1}
end

function PL_ChanHeader(num,units)
    
    if num<10
        c=string("sig00",num)
    elseif num<100
        c=string("sig0",num)
    else
        c=string("sig",num)
    end
    myname=zeros(UInt8,32)
    for i=1:length(c)
        myname[i]=convert(UInt8,c[i])
    end
    templates=zeros(Int16,5,64)
    fits=zeros(Int32,5)
    boxes=zeros(Int16,5,2,4)
    com=zeros(UInt8,128)
    pad=zeros(Int32,11)
    
    PL_ChanHeader(myname,myname,num,10,num,0,16,0,0,1,units,templates,fits,0,boxes,0,com,pad)
end

type PL_DataBlockHeader
    Type::Int16
    UpperByteOf5ByteTimestamp::UInt16
    TimeStamp::UInt32
    Channel::Int16
    Unit::Int16
    NumberOfWaveForms::Int16
    NumberOfWordsInWaveform::Int16
end 

function PL_DataBlockHeader(t,num,unit,wave_size)  
    PL_DataBlockHeader(1,0,t,num,unit,1,wave_size)
end

function write_plex(out_name::AbstractString,vname="v.bin",tsname="ts.bin",tmin=0)

    v_header=read_v_header(vname)
    ts_header=read_stamp_header(tsname)

    sample_size=v_header.samples_per_block
    sr=ts_header.sr
    
    (ss,numcells)=parse_ts(tsname)

    num_channel=length(ss)
    
    spikes=Intan.get_ts_dict(ss,numcells,tmin,sr)
    
    tscounts=zeros(Int32,130,5)
    
    for i=1:length(ss)
        for j=1:length(ss[i])
            tscounts[i+1,ss[i][j].id+1]+=1 
        end
    end

    samples_per_wave=convert(Int16,length(ss[1][1].inds))
    
    f_out=open(out_name,"a+")
    
    file_header=PL_FileHeader(sr,length(ss),samples_per_wave,24,ss[1][end].inds.stop/sr,tscounts)
    
    for i=1:length(fieldnames(file_header))
        write(f_out,getfield(file_header,i)) 
    end
    
    for i=1:length(ss)
        chan_header=PL_ChanHeader(i,numcells[i])
        for j=1:length(fieldnames(chan_header))
            write(f_out,getfield(chan_header,j)) 
        end
    end
    #This will suck for big files
    #should read in one channel voltage at a time
    v=parse_v(vname)
    
    myv=zeros(Int16,samples_per_wave)
    for i=1:length(ss)
        for j=1:length(ss[i])
            header=PL_DataBlockHeader(ss[i][j].inds.start,i,ss[i][j].id,samples_per_wave)
            myind=ss[i][j].inds.start
            
            if myind+samples_per_wave-1 < size(v,1)
                count=1
                for k=myind:(myind+samples_per_wave-1)                    
                    myv[count]=v[k,i]
                    count+=1
                end
                for k=1:length(fieldnames(header))
                    write(f_out,getfield(header,k)) 
                end
                write(f_out,myv)   
            end
        end
    end
        
    close(f_out)

    nothing
end
