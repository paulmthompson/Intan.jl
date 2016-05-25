#=

Methods for offline testing

=#

function Debug(filepath::ASCIIString, filetype::ASCIIString)

    if filetype=="qq"

        a=matread(filepath)
        md=squeeze(a["data"]',2).*1000
        d=Debug(true,"qq",md,1,floor(length(md)/SAMPLES_PER_DATA_BLOCK)*SAMPLES_PER_DATA_BLOCK) 
    end
    d
end

function readDataBlocks(rhd::RHD2000)

    fillFromOffline!(rhd)

    #Filter
    applyFilter(rhd)

    #Sort
    applySorting(rhd)
    nothing
end

function fillFromOffline!(rhd::RHD2000)

    toff=rhd.fpga[1].time[end]
    for j=1:SAMPLES_PER_DATA_BLOCK
        for i=1:size(rhd.v,2)  
            rhd.v[j,i]=round(Int16,rhd.debug.data[rhd.debug.ind])
        end
        rhd.debug.ind+=1
        rhd.fpga[1].time[j]=toff+j
    end

    if rhd.debug.ind>=rhd.debug.maxind
        rhd.debug.ind=1
    end
    nothing  
end
