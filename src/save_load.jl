
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
