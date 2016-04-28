
export save_jld, save_mat
#=
methods to select which variables in workspace to save
=#





#=
methods to load binary saved data
convert binary to jld files
=#

function get_spike_matrix(rhd::RHD2000)

    ss=[Array(Spike,0) for i=1:size(rhd.v,2)]
    
    numcells=zeros(Int64,size(rhd.v,2))

    f=open("ts.bin", "r+")

    while eof(f)==false

        t=read(f,UInt32,1)[1]

        for j=1:size(rhd.v,2)
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

function get_ts_dict(rhd::RHD2000,ss::Array{Array{Spike,1},1},numcells::Array{Int64,1},tmin=0)

    spikes=Dict{ASCIIString,Array{Int64,1}}()

    for i=1:length(numcells)
        for j=1:numcells[i]
            myname=string("s",i,"_",j)
            
            myspikes=zeros(Int64,0)
            
            for k=1:length(ss[i])
                if (ss[i][k].inds[1]>tmin) &&(ss[i][k].id==j)
                    push!(myspikes,ss[i][k].inds[1])
                end             
            end   
            spikes[myname]=myspikes
        end
    end
    spikes
end

function save_mat(rhd::RHD2000,tmin=0)

    (ss,numcells)=get_spike_matrix(rhd)
    
    spikes=get_ts_dict(rhd,ss,numcells,tmin)
    
    file = matopen("spikes.mat", "w")
    write(file, "spikes", spikes)
    close(file)
      
    spikes
end

function save_jld(rhd::Intan.RHD2000,tmin=0)

    (ss,numcells)=get_spike_matrix(rhd)

    spikes=get_ts_dict(rhd,ss,numcells,tmin)
    
    file = jldopen("spikes.jld", "w")
    write(file, "spikes", spikes)
    close(file)
      
    spikes
end
