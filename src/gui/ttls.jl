
function update_ttl_from_gui(han,fpga)

    c=channel
    d=fpga[1].d[c]

    update_ttl_trigger(han,d)

    if get_gtk_property(han.b["pulse_burst_combo"],:value,Int)==0 #pulse
        update_ttl_pulse(han,d)
    else
         update_ttl_burst(han,d)
    end

end

function update_ttl_trigger(han,d)

    #Trigger source

    if get_gtk_property(han.b["edge_trigger_combo"],:value,Int) == 0
        d.edgeTriggered = 0 #Edge Triggered
    else
        d.edgeTriggered = 1 #Level triggered
    end

    if get_gtk_property(han.b["high_low_trigger_combo"],:value,Int) == 0
        d.triggerOnLow = 0 #Trigger on High
    else
        d.triggerOnLow = 1 #Trigger on Low
    end

end

function update_ttl_pulse(han,d)

    pw = get_gtk_property(han.b["pulse_duration_train_sb"],:value,Int) #us
    period = get_gtk_property(han.b["pulse_period_train_sb"],:value,Int) * 1000 #convert ms to us

    d.pulseOrTrain = 0
    d.numPulses = 1
    d.firstPhaseDuration = pw
    d.refractoryPeriod = period - pw
    d.pulseTrainPeriod = period - pw

end

function update_ttl_burst(han,d)

    pw = get_gtk_property(han.b["pulse_duration_burst_sb"],:value,Int) #us
    period = get_gtk_property(han.b["pulse_period_burst_sb"]) * 1000 #convert ms to us
    num_pulses = get_gtk_property(han.b["num_pulses_sb"],:value,Int)

    d.pulseOrTrain = 1
    d.numPulses = num_pulses

    d.firstPhaseDuration = pw
    d.pulseTrainPeriod = period


    if get_gtk_property(han.b["repeat_burst_checkbox"],:active,Bool)
        d.refractoryPeriod = get_gtk_property(han.b["burst_period_burst_sb"],:value,Int) * 1000 #ms to us
    else
        #this effectively sets how long until next stimulation. don't want it to be too long
        d.refractoryPeriod = 1e6 * 10
    end
end

#=
mutable struct DigOut
    channel::Int32

    pulseOrTrain::Int32 #0 = single Pulse, 1 = pulse train

    triggerEnabled::Bool
    triggerOnLow::Bool # 0 = High Trigger, 1 = Low trigger
    edgeTriggered::Bool # 0 = edge, 1 = Level triggered
    triggerSource::Int32 #0 - 15 corresponds to digital in 1 through 16, 16-23 is analog inputs, 24 through 31 is keypresses

    shapeInt::Int32 # 0 = Biphasic, 1 = Biphasic with delay, 2 = Triphasic, 3 = monophasic
    negStimFirst::Bool # 0 = negative first, 1 = positive first
    numPulses::Int32

    postTriggerDelay::Int32 #after trigger, before pulse
    firstPhaseDuration::Int32
    refractoryPeriod::Int32
    pulseTrainPeriod::Int32
end
=#
