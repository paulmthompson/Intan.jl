
#const WireInStimRegAddr = 0x08;
#const WireInStimRegWord = 0x08;

function update_digital_output(fpga::FPGA,d::DigOut)

    stream = 16

    timestep_us = 1.0e6 / fpga.sampleRate

    #Trigger Paramters
    value = (d.triggerEnabled ? (1 << 7) : 0) + (d.triggerOnLow ? (1 << 6) : 0) + (d.edgeTriggered ? (1 << 5) : 0) + d.triggerSource;
    programStimReg(fpga,stream, d.channel, 0, value)

    #Number of Pulses
    value = (d.negStimFirst ? (1 << 10) : 0) + (d.shapeInt << 8) + (d.numPulses - 1);
    programStimReg(fpga,stream, d.channel, 1, value);

    postTriggerDelay = round(Int32,(d.postTriggerDelay / timestep_us + 0.5))
    firstPhaseDuration = round(Int32,(d.firstPhaseDuration / timestep_us + 0.5))
    refractoryPeriod = round(Int32,(d.refractoryPeriod / timestep_us + 0.5))
    pulseTrainPeriod = round(Int32,(d.pulseTrainPeriod / timestep_us + 0.5))

    eventStartStim = postTriggerDelay;
    eventEndStim = eventStartStim + firstPhaseDuration;
    eventEnd = eventEndStim + refractoryPeriod;

    eventRepeatStim = 0;

    if (d.pulseOrTrain == 1)
        eventRepeatStim = eventStartStim + pulseTrainPeriod;
    else
        eventRepeatStim = 4294967295;
    end

    #EventStartStim (post Trigger Delay) #These times are in units of clock ticks
    programStimReg(fpga, stream, d.channel, 4, eventStartStim);

    #eventEndStim (post Trigger Delay + Phase duration)
    programStimReg(fpga,stream, d.channel, 7, eventEndStim);

    #eventRepeatStim
    programStimReg(fpga,stream, d.channel, 8, eventRepeatStim);

    #event End
    programStimReg(fpga,stream, d.channel, 13, eventEnd);

end

function programStimReg(fpga,stream, channel, reg, value)

    if (OPEN_EPHYS)
        SetWireInValue(fpga,OPEN_EPHYS_WireInStimRegAddr, (stream << 8) + (channel << 4) + reg)
        SetWireInValue(fpga,OPEN_EPHYS_WireInStimRegWord, value)
    else
        SetWireInValue(fpga,WireInStimRegAddr, (stream << 8) + (channel << 4) + reg)
        SetWireInValue(fpga,WireInStimRegWord, value)
    end
    UpdateWireIns(fpga)
    if (OPEN_EPHYS)
        ActivateTriggerIn(fpga,OPEN_EPHYS_TrigInRamAddrReset, 1)
    else
        ActivateTriggerIn(fpga,TrigInRamAddrReset, 1)
    end
end
