

function _make_digital_output()





end

function ttl_cb(widget::Ptr,user_data::Tuple{Gui_Handles,RHD2000})

    han, rhd = user_data

    visible(han.b["digital_out_window"],true)
    nothing
end

function stim_update_cb(widget::Ptr,user_data::Tuple{Gui_Handles,FPGA})

    han, fpga = user_data

end


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
        d.repeatBurst=true
    else
        #this effectively sets how long until next stimulation. don't want it to be too long
        d.refractoryPeriod = 1e6 * 10
    end
end
