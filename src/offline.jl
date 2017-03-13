#=

Methods for offline testing

=#

function Debug(filepath::AbstractString, filetype::AbstractString)

    if filetype=="qq"

        a=matread(filepath)
        md=squeeze(a["data"]',2).*1000
        d=Debug(true,"qq",md,1,floor(length(md)/SAMPLES_PER_DATA_BLOCK)*SAMPLES_PER_DATA_BLOCK) 
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
        offline_cal(rhd,s,rhd.v,rhd.buf,rhd.nums)
    else
        offline_sort(rhd,s,rhd.v,rhd.buf,rhd.nums)
    end
    true
end

function offline_cal(rhd,s,v,buf,nums)
    @sync for p in procs(rhd.fpga)
        @spawnat p begin
            cal!(localpart(s),v,buf,nums)
        end 
    end
end

function offline_sort(rhd,s,v,buf,nums)
    @sync for p in procs(rhd.fpga)
        @spawnat p begin
            onlinesort!(localpart(s),v,buf,nums)
        end 
    end
end

function fillFromOffline!(rhd::RHD2000)

    toff=rhd.time[end,1]
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
    nothing  
end
