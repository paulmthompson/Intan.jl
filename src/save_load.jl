
export save_jld, save_mat, parse_v
#=
methods to select which variables in workspace to save
=#


#=
Turn binary file of voltages into matrix
=#

function parse_v(channel_num::Int64; name="v.bin", sample_size=SAMPLES_PER_DATA_BLOCK)

    f=open(name, "r+")

    seekend(f)
    l=position(f)
    v=zeros(Int16,div(l,(16*8)),channel_num)

    seekstart(f)

    count=0
    while eof(f)==false
        for i=1:channel_num
            for j=1:sample_size
                v[count+j,i]=read(f,Int16)
            end
        end
        count+=sample_size
    end
    close(f)
    v
end

#=
methods to load binary saved data
convert binary to jld files
=#

function get_spike_matrix(num_channel::Int64; name="ts.bin")

    ss=[Array(Spike,0) for i=1:num_channel]
    
    numcells=zeros(Int64,num_channel)

    f=open(name, "r+")

    while eof(f)==false

        t=read(f,UInt32,1)[1]

        for j=1:num_channel
            chan=read(f,Int64,1)[1] #channel
            num=read(f,Int64,1)[1]
            for i=1:num
                myss=read(f,Int64,2)
                if myss[2]>numcells[j]
                    numcells[j]=myss[2]
                end
                push!(ss[j],Spike((t+myss[1]:t+myss[1]),myss[2]))
            end
        end
    
    end

    close(f)

    (ss,numcells)
end


function get_ts_dict(ss::Array{Array{Spike,1},1},numcells::Array{Int64,1},tmin=0.0,sr=30000)

    spikes=Dict{ASCIIString,Array{Float64,1}}()

    for i=1:length(numcells)
        for j=1:numcells[i]
            myname=string("s",i,"_",j)
            
            myspikes=zeros(Float64,0)
            
            for k=1:length(ss[i])
                if (ss[i][k].inds[1]/sr>tmin) &&(ss[i][k].id==j)
                    push!(myspikes,ss[i][k].inds[1]/sr)
                end             
            end   
            spikes[myname]=myspikes
        end
    end
    spikes
end

function save_mat(num_channel::Int64; biname="ts.bin",savename="spikes.mat",tmin=0,sr=30000)

    (ss,numcells)=get_spike_matrix(num_channel,name=biname)
    
    spikes=get_ts_dict(ss,numcells,tmin,sr)
    
    file = matopen(savename, "w")
    write(file, "spikes", spikes)
    close(file)
      
    spikes
end

function save_jld(num_channel::Int64,biname="ts.bin",savename="spikes.jld",tmin=0.0,sr=30000)

    (ss,numcells)=get_spike_matrix(num_channel,name=biname)

    spikes=get_ts_dict(ss,numcells,tmin,sr)
    
    file = jldopen(savename, "w")
    write(file, "spikes", spikes)
    close(file)
      
    spikes
end

#=
Methods to convert data waveforms to PLX so it can be used with offline sorter.
Thanks to Simon Kornblith for linking to description of PLX data structures here:
http://hardcarve.com/wikipic/PlexonDataFileStructureDocumentation.pdf

These methods are specific for 
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

function write_plex(myname::ASCIIString,num_channel::Int64,sr=30000,tmin=0,sample_size=Intan.SAMPLES_PER_DATA_BLOCK)
    f_out=open(myname,"a+")
    
    (ss,numcells)=Intan.get_spike_matrix(num_channel)
    
    spikes=Intan.get_ts_dict(ss,numcells,tmin,sr)
    
    tscounts=zeros(Int32,130,5)
    
    for i=1:length(ss)
        for j=1:length(ss[i])
            tscounts[i+1,ss[i][j].id+1]+=1 
        end
    end
    
    file_header=PL_FileHeader(sr,length(ss),50,24,ss[1][end].inds[end]/sr,tscounts)
    
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
    v=parse_v(length(ss))
    myv=zeros(Int16,50)
    for i=1:length(ss)
        for j=1:length(ss[i])
            header=PL_DataBlockHeader(ss[i][j].inds[1],i,ss[i][j].id,50)
            myind=ss[i][j].inds[1]
            
            if myind+50 < size(v,1)
                count=1
                for k=myind:(myind+49)                    
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
