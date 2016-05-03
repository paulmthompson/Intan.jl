
export Task_TestTask


type Task_TestTask <: Task
end

function init_task(myt::Task_TestTask,rhd::RHD2000)
    setTtlOut(rhd,ones(Int32,16))
    nothing   
end

function do_task(myt::Task_TestTask,rhd::RHD2000)

    for i=1:SAMPLES_PER_DATA_BLOCK
        if rhd.adc[i,1]>10000
            setTtlOut(rhd,zeros(Int32,16))
            break
        end
    end
    
    nothing
end


function save_task(myt::Task_TestTask,rhd::RHD2000)

    f=open("adc1.bin","a+")
    for i=1:SAMPLES_PER_DATA_BLOCK
        write(f,rhd.adc[i,1])
    end
    close(f)
    nothing
end
