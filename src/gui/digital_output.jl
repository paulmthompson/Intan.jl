
function _make_digital_output()



end

function update_digital_output(fpga)

    stream = 16

    boardSampleRate=30000
    timestep_us = 1.0e6 / boardSampleRate;

    channel = 0
    pulseOrTrain = 0 #Single Pulse; 1 for Repeat Train


    #Trigger Paramters
    triggerEnabled = true
    triggerOnLow = false
    edgeTriggered = true
    triggerSource = 0 #0 - 15 corresponds to digital in 1 through 16
    value = (triggerEnabled ? (1 << 7) : 0) + (triggerOnLow ? (1 << 6) : 0) + (edgeTriggered ? (1 << 5) : 0) + triggerSource;
    programStimReg(fpga,stream, channel, 0, value)

    #Number of Pulses
    shapeInt = 3 #Monophasic
    negStimFirst = 0
    numPulses = 0
    value = (negStimFirst ? (1 << 10) : 0) + (shapeInt << 8) + (numPulses - 1);
    programStimReg(fpga,stream, channel, 1, value);

    postTriggerDelay = 0
    firstPhaseDuration = 1000
    refractoryPeriod = 5000
    pulseTrainPeriod = 5000

    postTriggerDelay = round(Int32,(postTriggerDelay / timestep_us + 0.5))
    firstPhaseDuration = round(Int32,(firstPhaseDuration / timestep_us + 0.5))
    refractoryPeriod = round(Int32,(refractoryPeriod / timestep_us + 0.5))
    pulseTrainPeriod = round(Int32,(pulseTrainPeriod / timestep_us + 0.5))

    eventStartStim = postTriggerDelay;
    eventEndStim = eventStartStim + firstPhaseDuration;
    eventEnd = eventEndStim + refractoryPeriod;

    eventRepeatStim = 0;

    if (pulseOrTrain == 1)
        eventRepeatStim = eventStartStim + pulseTrainPeriod;
    else
        eventRepeatStim = 65535;
    end

    #EventStartStim (post Trigger Delay) #These times are in units of clock ticks
    programStimReg(fpga, stream, channel, 4, eventStartStim);

    #eventEndStim (post Trigger Delay + Phase duration)
    programStimReg(fpga,stream, channel, 7, eventEndStim);

    #eventRepeatStim
    programStimReg(fpga,stream, channel, 8, eventRepeatStim);

    #event End
    programStimReg(fpga,stream, channel, 13, eventEnd);

end

function programStimReg(fpga,stream, channel, reg, value)

    SetWireInValue(fpga,WireInStimRegAddr, (stream << 8) + (channel << 4) + reg)
    SetWireInValue(fpga,WireInStimRegWord, value)
    UpdateWireIns(fpga)
    ActivateTriggerIn(fpga,TrigInRamAddrReset, 1)
end
