
function enableDac(rhd::FPGA,dacChannel::Int,enabled::Bool)

    #error checking goes here

    if rhd.usb3
        if (OPEN_EPHYS)
            dacEnMask = 0x0400
        else
            dacEnMask = 0x0800
        end
    else
        dacEnMask = 0x0200
    end


    if dacChannel == 0
        SetWireInValue(rhd,WireInDacSource1,(enabled ? dacEnMask : 0x0000), dacEnMask)
    elseif dacChannel == 1
        SetWireInValue(rhd,WireInDacSource2,(enabled ? dacEnMask : 0x0000), dacEnMask)
    elseif dacChannel == 2
        SetWireInValue(rhd,WireInDacSource3,(enabled ? dacEnMask : 0x0000), dacEnMask)
    elseif dacChannel == 3
        SetWireInValue(rhd,WireInDacSource4,(enabled ? dacEnMask : 0x0000), dacEnMask)
    elseif dacChannel == 4
        SetWireInValue(rhd,WireInDacSource5,(enabled ? dacEnMask : 0x0000), dacEnMask)
    elseif dacChannel == 5
        SetWireInValue(rhd,WireInDacSource6,(enabled ? dacEnMask : 0x0000), dacEnMask)
    elseif dacChannel == 6
        SetWireInValue(rhd,WireInDacSource7,(enabled ? dacEnMask : 0x0000), dacEnMask)
    elseif dacChannel == 7
        SetWireInValue(rhd,WireInDacSource8,(enabled ? dacEnMask : 0x0000), dacEnMask)
    end

    UpdateWireIns(rhd)

    nothing
end

function selectDacDataStream(rhd::FPGA,dacChannel, stream)
    #error checking goes here

    if rhd.usb3
        if (OPEN_EPHYS)
            dacStreamMask = 0x03e0
        else
            dacStreamMask = 0x07e0
        end
    else
        dacStreamMask = 0x01e0
    end

    if dacChannel == 0
         SetWireInValue(rhd,WireInDacSource1, stream << 5, dacStreamMask)
    elseif dacChannel == 1
         SetWireInValue(rhd,WireInDacSource2, stream << 5, dacStreamMask)
    elseif dacChannel == 2
         SetWireInValue(rhd,WireInDacSource3, stream << 5, dacStreamMask)
    elseif dacChannel == 3
         SetWireInValue(rhd,WireInDacSource4, stream << 5, dacStreamMask)
    elseif dacChannel == 4
         SetWireInValue(rhd,WireInDacSource5, stream << 5, dacStreamMask)
    elseif dacChannel == 5
         SetWireInValue(rhd,WireInDacSource6, stream << 5, dacStreamMask)
    elseif dacChannel == 6
         SetWireInValue(rhd,WireInDacSource7, stream << 5, dacStreamMask)
    elseif dacChannel == 7
         SetWireInValue(rhd,WireInDacSource8, stream << 5, dacStreamMask)
    end

    UpdateWireIns(rhd)

    nothing
end

function selectDacDataChannel(rhd::FPGA,dacChannel::Int, dataChannel)
    #error checking goes here

    if dacChannel == 0
        SetWireInValue(rhd,WireInDacSource1,dataChannel << 0, 0x001f)
    elseif dacChannel == 1
        SetWireInValue(rhd,WireInDacSource2,dataChannel << 0, 0x001f)
    elseif dacChannel == 2
        SetWireInValue(rhd,WireInDacSource3,dataChannel << 0, 0x001f)
    elseif dacChannel == 3
        SetWireInValue(rhd,WireInDacSource4,dataChannel << 0, 0x001f)
    elseif dacChannel == 4
        SetWireInValue(rhd,WireInDacSource5,dataChannel << 0, 0x001f)
    elseif dacChannel == 5
        SetWireInValue(rhd,WireInDacSource6,dataChannel << 0, 0x001f)
    elseif dacChannel == 6
        SetWireInValue(rhd,WireInDacSource7,dataChannel << 0, 0x001f)
    elseif dacChannel == 7
        SetWireInValue(rhd,WireInDacSource8,dataChannel << 0, 0x001f)
    end

    UpdateWireIns(rhd)

    nothing
end

setDacManual(rhd::FPGA,value)=(SetWireInValue(rhd,WireInDacManual,value);UpdateWireIns(rhd))

setDacGain(rhd::FPGA,gain)=(SetWireInValue(rhd,WireInResetRun,gain<<13,0xe000);UpdateWireIns(rhd))

setAudioNoiseSuppress(rhd::FPGA,noiseSuppress)=(SetWireInValue(rhd,WireInResetRun,noiseSuppress<<6,0x1fc0);UpdateWireIns(rhd))

function setDacThreshold(rhd::FPGA,dacChannel, threshold, trigPolarity)

    #error checking goes here

    #Set threshold level
    SetWireInValue(rhd,WireInMultiUse,threshold)
    UpdateWireIns(rhd)
    if (OPEN_EPHYS)
        ActivateTriggerIn(rhd,TrigInDacThresh, dacChannel)
    else
        ActivateTriggerIn(rhd,TrigInDacConfig, dacChannel)
    end

    #Set threshold polarity
    SetWireInValue(rhd,WireInMultiUse, (trigPolarity ? 1 : 0))
    UpdateWireIns(rhd)
    if (OPEN_EPHYS)
        ActivateTriggerIn(rhd,TrigInDacThresh, dacChannel+8)
    else
        ActivateTriggerIn(rhd,TrigInDacConfig, dacChannel+8)
    end

    nothing
end
