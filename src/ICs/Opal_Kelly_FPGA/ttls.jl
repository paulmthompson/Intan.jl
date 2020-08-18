
function setTtlMode(rhd::FPGA,mode)

    value = 0;
    value += mode[1] ? 1 : 0;
    value += mode[2] ? 2 : 0;
    value += mode[3] ? 4 : 0;
    value += mode[4] ? 8 : 0;
    value += mode[5] ? 16 : 0;
    value += mode[6] ? 32 : 0;
    value += mode[7] ? 64 : 0;
    value += mode[8] ? 128 : 0;

    SetWireInValue(rhd,WireInTtlOut,value,0x000000ff)
    UpdateWireIns(rhd)
end

function manual_trigger(rhd,trigger,triggerOn)
    #Trigger 0-7
    SetWireInValue(rhd,WireInManualTriggers, (triggerOn ? 1 : 0) << trigger,1<<trigger);
    UpdateWireIns(rhd)
end

clearTtlOut(rhd::FPGA)=(SetWireInValue(rhd,WireInTtlOut, 0x0000);UpdateWireIns(rhd))

function getTtlIn(rhd::FPGA,ttlInArray)

    UpdateWireOuts(rhd)
    ttlIn=GetWireOutValue(rhd,WireOutTtlIn)
    for i=1:16
        ttlInArray[i] = 0
        if (ttlIn & (1 << (i-1))) > 0
            ttlInArray[i] = 1
        end
    end

    ttlInArray
end

function setTtlOut(rhd::FPGA,ttlOutArray)

    ttlOut=Int32(0)
    for i=1:16
        if ttlOutArray[i]>0
            ttlOut += (1<< (i-1))
        end
    end

    SetWireInValue(rhd,WireInTtlOut,ttlOut)
    UpdateWireIns(rhd)
    nothing
end

function sendTimePulse(fpga::FPGA,val::Bool)

    if val==true
        fpga.ttloutput += (1 << (16-1))
    else
        fpga.ttloutput -= (1 << (16-1))
    end

    SetWireInValue(fpga,WireInTtlOut,fpga.ttloutput)
    UpdateWireIns(fpga)
    nothing
end

#=
Fast settle function allows TTL inputs to black amplifier channels
Can be used to prevent amplifiers from saturation (such as during stimulation)
=#
function enableExternalFastSettle(rhd::FPGA,enable)

    SetWireInValue(rhd,WireInMultiUse, (enable ? 1 : 0))
    UpdateWireIns(rhd)
    if (OPEN_EPHYS)
        ActivateTriggerIn(rhd,TrigInExtFastSettle,0)
    else
        ActivateTriggerIn(rhd,TrigInConfig,6)
    end

    nothing
end

function setExternalFastSettleChannel(rhd::FPGA,channel)

    #error checking goes here

    SetWireInValue(rhd,WireInMultiUse,channel)
    UpdateWireIns(rhd)
    if (OPEN_EPHYS)
        ActivateTriggerIn(rhd,TrigInExtFastSettle,1)
    else
        ActivateTriggerIn(rhd,TrigInConfig,7)
    end
end
