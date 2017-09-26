#=

Methods for offline testing

=#

function Debug(filepath::AbstractString, filetype::AbstractString)

    if filetype=="qq"

        a=matread(filepath)
        md=squeeze(a["data"]',2).*-1000
        d=Debug(true,"qq",filepath,md,1,floor(length(md)/SAMPLES_PER_DATA_BLOCK)*SAMPLES_PER_DATA_BLOCK) 
    elseif filetype=="Intan"

        myheader = read_v_header(filepath)

        f=open(filepath, "r+")

        seekend(f)

        endpos = position(f)

        close(f)

        d=Debug(true,"Intan",filepath,zeros(Int16,1),10,endpos)
    end
    d
end

function readDataBlocks{T<:Sorting}(rhd::RHD2000,s::Array{T,1})
    fillFromOffline!(rhd)
    applySorting(rhd,s)
    true
end

function readDataBlocks{T<:Sorting}(rhd::RHD2000,s::DArray{T,1,Array{T,1}})
    fillFromOffline!(rhd)
    if rhd.cal<3
        offline_cal(s,rhd.v,rhd.buf,rhd.nums)
    else
        offline_sort(s,rhd.v,rhd.buf,rhd.nums)
    end
    true
end

function offline_cal(s,v,buf,nums)
    @sync for p in procs(s)
        @spawnat p begin
            cal!(localpart(s),v,buf,nums)
        end 
    end
end

function offline_sort(s,v,buf,nums)
    @sync for p in procs(s)
        @spawnat p begin
            onlinesort!(localpart(s),v,buf,nums)
        end 
    end
end

function fillFromOffline!(rhd::RHD2000)

    toff=rhd.time[end,1]

    if rhd.debug.m == "qq"
    
        for j=1:SAMPLES_PER_DATA_BLOCK
            for i=1:size(rhd.v,2)  
                rhd.v[j,i]=round(Int16,rhd.debug.data[rhd.debug.ind])
            end
            rhd.debug.ind+=1
            rhd.time[j,1]=toff+j
        end
        if rhd.debug.ind>=rhd.debug.maxind
            rhd.debug.ind=1
        end
    elseif rhd.debug.m == "Intan"

        f=open(rhd.debug.filepath, "r+")

        seek(f,rhd.debug.ind)

        for i=1:size(rhd.v,2)
            for j=1:SAMPLES_PER_DATA_BLOCK
                rhd.v[j,i]=read(f,Int16)
            end
        end

        for j=1:SAMPLES_PER_DATA_BLOCK
            rhd.time[j,1]=toff+j
        end

        rhd.debug.ind = position(f)
        

        close(f)
        if rhd.debug.ind>=rhd.debug.maxind
            rhd.debug.ind=10
        end
    end
    #Filter
    for i=1:length(rhd.filts)
        for j=1:length(rhd.filts[i])
            apply_filter(rhd,rhd.filts[i][j],rhd.filts[i][j].chan)
        end
    end
    nothing  
end
