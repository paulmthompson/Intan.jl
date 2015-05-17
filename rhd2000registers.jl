module rhd2000registers

export CreateRHD2000Registers, createCommandListRegisterConfig, setDspCutoffFreq, setLowerBandwidth, setUpperBandwidth

type register
    sampleRate::Cdouble

    #Register 0 variables
    adcReferenceBw::Int32
    ampFastSettle::Int32
    ampVrefEnable::Int32
    adcComparatorBias::Int32
    adcComparatorSelect::Int32

    #Register 1 variables
    vddSenseEnable::Int32
    adcBufferBias::Int32

    #Register 2 variables
    muxBias::Int32

    #Register 3 variables
    muxLoad::Int32
    tempS1::Int32
    tempS2::Int32
    tempEn::Int32
    digOutHiZ::Int32
    digOut::Int32

    #Register 4 variables
    weakMiso::Int32
    twosComp::Int32
    absMode::Int32
    dspEn::Int32
    dspCutoffFreq::Int32

    #Register 5 variables
    zcheckDacPower::Int32
    zcheckLoad::Int32
    zcheckScale::Int32
    zcheckConnAll::Int32
    zcheckSelPol::Int32
    zcheckEn::Int32

    #Register 6 variables

    #Register 7 variables
    zcheckSelect::Int32

    #Register 8-13 variables
    offChipRH1::Int32
    offChipRH2::Int32
    offChipRL::Int32
    adcAux1En::Int32
    adcAux2En::Int32
    adcAux3En::Int32
    rH1Dac1::Int32
    rH1Dac2::Int32
    rH2Dac1::Int32
    rH2Dac2::Int32
    rLDac1::Int32
    rLDac2::Int32
    rLDac3::Int32

    #Register 14-17 variables
    aPwr::Array{Int32,1}

end

function CreateRHD2000Registers(sampleRate)   

    r=register(zeros(Int32,40)...,zeros(Int32,1))
    
    defineSampleRate(sampleRate,r)
    
    r.adcReferenceBw = 3

    r=setFastSettle(false,r)

    r.ampVrefEnable=1

    r.adcComparatorBias=3

    r.adcComparatorSelect=2

    r.vddSenseEnable=1

    r.tempS1=0
    r.tempS2=0
    r.tempEn=0
    r=setDigOutHiZ(r)

    r.weakMiso=1

    r.twosComp=0

    r.absMode=0

    r=enableDsp(true,r)

    r=setDspCutoffFreq(1.0,r)

    r.zcheckDacPower=1

    r.zcheckLoad=0

    r=setZcheckScale("ZcheckCs100fF",r)

    r.zcheckConnAll=0

    r=setZcheckPolarity("ZcheckPositiveInput",r)

    r=enableZcheck(false,r)

    r=setZcheckChannel(0,r)

    r.offChipRH1=0
    r.offChipRH2=0
    r.offChipRL=0
    r.adcAux1En=1
    r.adcAux2En=1
    r.adcAux3En=1

    #not sure what these actually do
    r=setUpperBandwidth(10000.0,r)
    r=setLowerBandwidth(1.0,r)

    r=powerUpAllAmps(r)

    return r

end

function defineSampleRate(newSampleRate,r)
    
    r.sampleRate=newSampleRate

    r.muxLoad=0

    if r.sampleRate<3334.0
        r.muxBias=40
        r.adcBufferBias=32
    elseif r.sampleRate<4001.0
        r.muxBias=40
        r.adcBufferBias=16
    elseif r.sampleRate<5001.0
        r.muxBias=40
        r.adcBufferBias=8
    elseif r.sampleRate<6251.0
        r.muxBias=32
        r.adcBufferBias=8
    elseif r.sampleRate<8001.0
        r.muxBias=26
        r.adcBufferBias=8
    elseif r.sampleRate<10001.0
        r.muxBias=18
        r.adcBufferBias=4
    elseif r.sampleRate<12501.0
        r.muxBias=16
        r.adcBufferBias=3
    elseif r.sampleRate<15001.0
        r.muxBias=7
        r.adcBufferBias=3
    else
        r.muxBias=4
        r.adcBufferBias=2
    end

    return r
    
end

function setFastSettle(enabled, r)

    r.ampFastSettle=(enabled ? 1 : 0)

    return r

end

function setDigOutLow(r)

    r.digOut=0
    r.digOutHiZ=0

    return r

end

function setDigOutHigh(r)

    r.digOut=1
    r.digOutHiZ=0

    return r

end

function setDigOutHiZ(r)

    r.digOut=0
    r.digOutHiZ=1

    return r

end

function setDspCutoffFreq(newDspCutoffFreq, r)
  
    logNewDspCutoffFreq = log10(newDspCutoffFreq)
    fCutoff=zeros(Float64,16)
    logFCutoff=zeros(Float64,16)

    for n=2:16
        x= 2.0 ^ (n-1)
        fCutoff[n]= r.sampleRate * log(x / (x - 1.0)) / * (2*pi)
        logFCutoff[n] = log10(fCutoff[n])
    end

    if newDspCutoffFreq > fCutoff[2]
        r.dspCutoffFreq = 2
    elseif newDspCutoffFreq < fCutoff[16]
        r.dspCutoffFreq = 16
    else
        minLogDiff = 10000000.0
        for n=2:16
            if (abs(logNewDspCutoffFreq - logFCutoff[n]) < minLogDiff)
                minLogDiff = abs(logNewDspCutoffFreq - logFCutoff[n]);
                r.dspCutoffFreq = n;
            end
        end
    end
    
    return r
   
end


function enableAux1(enabled, r)

    r.adcAux1En = (enabled ? 1 : 0)

    return r

end

function enableAux2(enabled, r)

    r.adcAux2En = (enabled ? 1 : 0)

    return r

end

function enableAux3(enabled, r)

    r.adcAux3En = (enabled ? 1: 0)

    return r

end

function enableDsp(enabled, r)

    r.dspEn = (enabled ? 1 : 0)

    return r

end

function enableZcheck(enabled, r)

    r.zcheckEn = (enabled ? 1 : 0)

    return r

end

function setZcheckDacPower(enabled, r)

    r.zcheckDacPower = (enabled ? 1 : 0)

    return r

end

function setZcheckScale(scale, r)

    if scale=="ZcheckCs100fF"
        r.zcheckScale = 0x00
    elseif scale=="ZcheckCs1pF"
        r.zcheckScale = 0x01
    elseif scale=="ZcheckCs10pF"
        r.zcheckScale = 0x03
    end

    return r

end

function setZcheckPolarity(polarity, r)

    if polarity=="ZcheckPositiveInput"
        r.zcheckSelPol=0
    elseif polarity=="ZcheckNegativeInput"
        r.zcheckSelPol=1
    end

    return r

end

function setZcheckChannel(channel, r)
    r.zcheckSelect=channel
    return r
end


function powerUpAllAmps(r)

    r.aPwr=ones(Int32, 64)

    return r

end

function powerDownAllAmps(r)

    r.aPwr=zeros(Int32,64)

    return r

end

function setLowerBandwidth(lowerBandwidth, r)

    const RLBase = 3500.0
    const RLDac1Unit = 175.0
    const RLDac2Unit = 12700.0
    const RLDac3Unit = 3000000.0
    const RLDac1Steps = 127
    const RLDac2Steps = 63

    if lowerBandwidth > 1500.0
        lowerBandwidth = 1500.0
    end

    rLTarget = rLFromLowerBandwidth(lowerBandwidth)

    r.rLDac1 = 0
    r.rLDac2 = 0
    r.rLDac3 = 0
    rLActual = RLBase

    if lowerBandwidth < 0.15
        rLActual += RLDac3Unit
        r.rLDac3+=1
    end

    for i=1:RLDac2Steps
        if rLActual < rLTarget - (RLDac2Unit - RLDac1Unit/2)
            rLActual += RLDac2Unit
            r.rLDac2+=1
        end
    end

    for i=1:RLDac1Steps
        if rLActual < rLTarget - (RLDac1Unit /2)
            rLActual += RLDac1Unit
            r.rLDac1+=1
        end
    end

    actualLowerBandwidth=lowerBandwidthFromRL(rLActual)

    return r

end

function setUpperBandwidth(upperBandwidth, r)

    const RH1Base = 2200.0
    const RH1Dac1Unit = 600.0
    const RH1Dac2Unit = 29400.0
    const RH1Dac1Steps = 63
    const RH1Dac2Steps = 31

    const RH2Base = 8700.0
    const RH2Dac1Unit = 763.0
    const RH2Dac2Unit = 38400.0
    const RH2Dac1Steps = 63
    const RH2Dac2Steps = 31

    if upperBandwidth > 30000.0
        upperBandwidth = 30000.0
    end

    rH1Target = rH1FromUpperBandwidth(upperBandwidth)

    r.rH1Dac1 = 0
    r.rH1Dac2 = 0
    rH1Actual = RH1Base

    for i=1:RH1Dac2Steps

        if rH1Actual < rH1Target - (RH1Dac2Unit - RH1Dac1Unit/2)
            rH1Actual += RH1Dac2Unit
            r.rH1Dac2+=1
        end
        
    end

    for i=1:RH1Dac1Steps

        if rH1Actual < rH1Target - (RH1Dac1Unit/2)
            rH1Actual += RH1Dac1Unit
            r.rH1Dac1+=1
        end
    end

    rH2Target= rH2FromUpperBandwidth(upperBandwidth)

    r.rH2Dac1=0
    r.rH2Dac2=0
    rH2Actual = RH2Base

    for i=1:RH2Dac2Steps

        if rH2Actual < rH2Target - (RH2Dac2Unit - RH2Dac1Unit/2)
            rH2Actual += RH2Dac2Unit
            r.rH2Dac2+=1
        end
        
    end

    for i=1:RH2Dac1Steps

        if rH2Actual < rH2Target - (RH2Dac1Unit/2)
            rH2Actual += RH2Dac1Unit
            r.rH2Dac1+=1
        end
    end

    actualUpperBandwidth1 = upperBandwidthFromRH1(rH1Actual)
    actualUpperBandwidth2 = upperBandwidthFromRH2(rH2Actual)

    actualUpperBandwidth = sqrt(actualUpperBandwidth1 * actualUpperBandwidth2)

    return r
       
end

function rLFromLowerBandwidth(lowerBandwidth)

    log10f = log10(lowerBandwidth)

    if (lowerBandwidth < 4.0) 
       return 1.0061 * 10.0 ^ (4.9391 - 1.2088 * log10f + 0.5698 * log10f * log10f + 0.1442 * log10f * log10f * log10f)
    
    else 
        return 1.0061 * 10.0 ^ (4.7351 - 0.5916 * log10f + 0.08482 * log10f * log10f)
    end
   
end

function rH1FromUpperBandwidth(upperBandwidth)

    log10f = log10(upperBandwidth)

    return 0.9730 * 10.0 ^ (8.0968 - 1.1892 * log10f + 0.04767 * log10f * log10f)
    
end

function rH2FromUpperBandwidth(upperBandwidth)

    log10f = log10(upperBandwidth)

    return 1.0191 * 10.0 ^ (8.1009 - 1.0821 * log10f + 0.03383 * log10f * log10f)

end

function upperBandwidthFromRH1(rH1)
    
    a = 0.04767
    b = -1.1892
    c = 8.0968 - log10(rH1/0.9730)

    return 10.0 ^ ((-b - sqrt(b * b - 4 * a * c))/(2 * a))

end

function upperBandwidthFromRH2(rH2)

    a = 0.03383
    b = -1.0821
    c = 8.1009 - log10(rH2/1.0191)

    return 10.0 ^ ((-b - sqrt(b * b - 4 * a * c))/(2 * a))

end

function lowerBandwidthFromRL(rL)

    if (rL < 5100.0) 
        rL = 5100.0
    end

    if (rL < 30000.0)
        a = 0.08482
        b = -0.5916
        c = 4.7351 - log10(rL/1.0061)
    else 
        a = 0.3303
        b = -1.2100
        c = 4.9873 - log10(rL/1.0061)
    end
     
    return 10.0 ^ ((-b - sqrt(b * b - 4 * a * c))/(2 * a))

end

function createRhd2000Command(commandType, arg1=0, arg2=0)

    if commandType=="Rhd2000CommandCalibrate"
        return 0x5500
    elseif commandType=="Rhd2000CommandCalClear"
        return 0x6a00
    elseif commandType=="Rhd2000CommandConvert"
        return 0x0000 + (arg1 << 8)
    elseif commandType=="Rhd2000CommandRegRead"
        return 0xc000 + (arg1 << 8)
    elseif commandType=="Rhd2000CommandRegWrite"
        return 0x8000 + (arg1 << 8) + arg2
    end

end

function getRegisterValue(reg, r)

    zcheckDac=128

    aPwr=r.aPwr
    
    if reg==0
        regout = (r.adcReferenceBw << 6) + (r.ampFastSettle << 5) + (r.ampVrefEnable << 4) +
        (r.adcComparatorBias << 2) + r.adcComparatorSelect
    elseif reg==1
        regout = (r.vddSenseEnable << 6) + r.adcBufferBias
    elseif reg==2
        regout = r.muxBias
    elseif reg==3
        regout = (r.muxLoad << 5) + (r.tempS2 << 4) + (r.tempS1 << 3) + (r.tempEn << 2) +
        (r.digOutHiZ << 1) + r.digOut
    elseif reg==4
        regout = (r.weakMiso << 7) + (r.twosComp << 6) + (r.absMode << 5) + (r.dspEn << 4) +
        r.dspCutoffFreq
    elseif reg==5
        regout = (r.zcheckDacPower << 6) + (r.zcheckLoad << 5) + (r.zcheckScale << 3) +
        (r.zcheckConnAll << 2) + (r.zcheckSelPol << 1) + r.zcheckEn
    elseif reg==6
        regout = zcheckDac
    elseif reg==7
        regout = r.zcheckSelect
    elseif reg==8
        regout = (r.offChipRH1 << 7) + r.rH1Dac1
    elseif reg==9
        regout = (r.adcAux1En << 7) + r.rH1Dac2
    elseif reg==10
        regout = (r.offChipRH2 << 7) + r.rH2Dac1
    elseif reg==11
        regout = (r.adcAux2En << 7) + r.rH2Dac2
    elseif reg==12
        regout = (r.offChipRL << 7) + r.rLDac1
    elseif reg==13
        regout = (r.adcAux3En << 7) + (r.rLDac3 << 6) + r.rLDac2
    elseif reg==14
        regout = (aPwr[8] << 7) + (aPwr[7] << 6) + (aPwr[6] << 5) + (aPwr[5] << 4) +
        (aPwr[4] << 3) + (aPwr[3] << 2) + (aPwr[2] << 1) + aPwr[1]
    elseif reg==15
        regout = (aPwr[16] << 7) + (aPwr[15] << 6) + (aPwr[14] << 5) + (aPwr[13] << 4) +
        (aPwr[12] << 3) + (aPwr[11] << 2) + (aPwr[10] << 1) + aPwr[1]
    elseif reg==16
        regout = (aPwr[24] << 7) + (aPwr[23] << 6) + (aPwr[22] << 5) + (aPwr[21] << 4) +
        (aPwr[20] << 3) + (aPwr[19] << 2) + (aPwr[18] << 1) + aPwr[17]
    elseif reg==17
        regout = (aPwr[32] << 7) + (aPwr[31] << 6) + (aPwr[30] << 5) + (aPwr[29] << 4) +
        (aPwr[28] << 3) + (aPwr[27] << 2) + (aPwr[26] << 1) + aPwr[25]
    elseif reg==18
        regout = (aPwr[40] << 7) + (aPwr[39] << 6) + (aPwr[38] << 5) + (aPwr[37] << 4) +
        (aPwr[36] << 3) + (aPwr[35] << 2) + (aPwr[34] << 1) + aPwr[33]
    elseif reg==19
        regout = (aPwr[48] << 7) + (aPwr[47] << 6) + (aPwr[46] << 5) + (aPwr[45] << 4) +
        (aPwr[44] << 3) + (aPwr[43] << 2) + (aPwr[42] << 1) + aPwr[41]
    elseif reg==20
        regout = (aPwr[56] << 7) + (aPwr[55] << 6) + (aPwr[54] << 5) + (aPwr[53] << 4) +
        (aPwr[52] << 3) + (aPwr[51] << 2) + (aPwr[50] << 1) + aPwr[49]
    elseif reg==21
        regout = (aPwr[64] << 7) + (aPwr[63] << 6) + (aPwr[62] << 5) + (aPwr[61] << 4) +
        (aPwr[60] << 3) + (aPwr[59] << 2) + (aPwr[58] << 1) + aPwr[57]
    end

    return regout
        
end

#Create a list of 60 commands to program most RAM registers on a RHD2000 chip, read those values back to confirm programming, read ROM registers, and (if calibrate == true) run ADC calibration.

function createCommandListRegisterConfig(commandList, calibrate, r)

    #Start with a few dummy commands in case chip is still powering up
    push!(commandList, createRhd2000Command("Rhd2000CommandRegRead", 63))
    splice!(commandList,1) #remove first dummy command
    push!(commandList, createRhd2000Command("Rhd2000CommandRegRead", 63))

    #Program RAM registers
    push!(commandList, createRhd2000Command("Rhd2000CommandRegWrite", 0, getRegisterValue(0, r)))
    push!(commandList, createRhd2000Command("Rhd2000CommandRegWrite", 1, getRegisterValue(1, r)))
    push!(commandList, createRhd2000Command("Rhd2000CommandRegWrite", 2, getRegisterValue(2, r)))

    #Don't program Register 3 (MUX Load, Temperature Sensor, and Auxiliary Digital Output)

    #control temperature sensor in another command stream
    push!(commandList, createRhd2000Command("Rhd2000CommandRegWrite", 4, getRegisterValue(4, r)))
    push!(commandList, createRhd2000Command("Rhd2000CommandRegWrite", 5, getRegisterValue(5, r)))

    #Don't program Register 6 (Impedence Check DAC) here; create DAC waveform in another command stream
    push!(commandList, createRhd2000Command("Rhd2000CommandRegWrite", 7, getRegisterValue(7, r)))
    push!(commandList, createRhd2000Command("Rhd2000CommandRegWrite", 8, getRegisterValue(8, r)))
    push!(commandList, createRhd2000Command("Rhd2000CommandRegWrite", 9, getRegisterValue(9, r)))
    push!(commandList, createRhd2000Command("Rhd2000CommandRegWrite", 10, getRegisterValue(10, r)))
    push!(commandList, createRhd2000Command("Rhd2000CommandRegWrite", 11, getRegisterValue(11, r)))
    push!(commandList, createRhd2000Command("Rhd2000CommandRegWrite", 12, getRegisterValue(12, r)))
    push!(commandList, createRhd2000Command("Rhd2000CommandRegWrite", 13, getRegisterValue(13, r)))
    push!(commandList, createRhd2000Command("Rhd2000CommandRegWrite", 14, getRegisterValue(14, r)))
    push!(commandList, createRhd2000Command("Rhd2000CommandRegWrite", 15, getRegisterValue(15, r)))
    push!(commandList, createRhd2000Command("Rhd2000CommandRegWrite", 16, getRegisterValue(16, r)))
    push!(commandList, createRhd2000Command("Rhd2000CommandRegWrite", 17, getRegisterValue(17, r)))

    
    #Read ROM registers
    push!(commandList, createRhd2000Command("Rhd2000CommandRegRead", 63))
    push!(commandList, createRhd2000Command("Rhd2000CommandRegRead", 62))
    push!(commandList, createRhd2000Command("Rhd2000CommandRegRead", 61))
    push!(commandList, createRhd2000Command("Rhd2000CommandRegRead", 60))
    push!(commandList, createRhd2000Command("Rhd2000CommandRegRead", 59))

    #Read chip name from ROM
    push!(commandList, createRhd2000Command("Rhd2000CommandRegRead", 48))
    push!(commandList, createRhd2000Command("Rhd2000CommandRegRead", 49))
    push!(commandList, createRhd2000Command("Rhd2000CommandRegRead", 50))
    push!(commandList, createRhd2000Command("Rhd2000CommandRegRead", 51))
    push!(commandList, createRhd2000Command("Rhd2000CommandRegRead", 52))
    push!(commandList, createRhd2000Command("Rhd2000CommandRegRead", 53))
    push!(commandList, createRhd2000Command("Rhd2000CommandRegRead", 54))
    push!(commandList, createRhd2000Command("Rhd2000CommandRegRead", 55))

    #Read Intan name from ROM
    push!(commandList, createRhd2000Command("Rhd2000CommandRegRead", 40))
    push!(commandList, createRhd2000Command("Rhd2000CommandRegRead", 41))
    push!(commandList, createRhd2000Command("Rhd2000CommandRegRead", 42))
    push!(commandList, createRhd2000Command("Rhd2000CommandRegRead", 43))
    push!(commandList, createRhd2000Command("Rhd2000CommandRegRead", 44))

    #Read back RAM registers to confirm programming
    push!(commandList, createRhd2000Command("Rhd2000CommandRegRead", 0))
    push!(commandList, createRhd2000Command("Rhd2000CommandRegRead", 1))
    push!(commandList, createRhd2000Command("Rhd2000CommandRegRead", 2))
    push!(commandList, createRhd2000Command("Rhd2000CommandRegRead", 3))
    push!(commandList, createRhd2000Command("Rhd2000CommandRegRead", 4))
    push!(commandList, createRhd2000Command("Rhd2000CommandRegRead", 5))
    push!(commandList, createRhd2000Command("Rhd2000CommandRegRead", 6))
    push!(commandList, createRhd2000Command("Rhd2000CommandRegRead", 7))
    push!(commandList, createRhd2000Command("Rhd2000CommandRegRead", 8))
    push!(commandList, createRhd2000Command("Rhd2000CommandRegRead", 9))
    push!(commandList, createRhd2000Command("Rhd2000CommandRegRead", 10))
    push!(commandList, createRhd2000Command("Rhd2000CommandRegRead", 11))
    push!(commandList, createRhd2000Command("Rhd2000CommandRegRead", 12))
    push!(commandList, createRhd2000Command("Rhd2000CommandRegRead", 13))
    push!(commandList, createRhd2000Command("Rhd2000CommandRegRead", 14))
    push!(commandList, createRhd2000Command("Rhd2000CommandRegRead", 15))
    push!(commandList, createRhd2000Command("Rhd2000CommandRegRead", 16))
    push!(commandList, createRhd2000Command("Rhd2000CommandRegRead", 17))

    #Optionally, run ADC calibration (should only be run once after board is plugged in
    if calibrate
        push!(commandList, createRhd2000Command("Rhd2000CommandCalibrate"))
    else
        push!(commandList, createRhd2000Command("Rhd2000CommandRegRead",63))
    end
    
    #Program amplifier 31-63 power up/down registers in case RHD2164 is connected
    push!(commandList, createRhd2000Command("Rhd2000CommandRegWrite",18,getRegisterValue(18,r)))
    push!(commandList, createRhd2000Command("Rhd2000CommandRegWrite",19,getRegisterValue(19,r)))
    push!(commandList, createRhd2000Command("Rhd2000CommandRegWrite",20,getRegisterValue(20,r)))
    push!(commandList, createRhd2000Command("Rhd2000CommandRegWrite",21,getRegisterValue(21,r)))
    
    #End with a dummy command
    push!(commandList, createRhd2000Command("Rhd2000CommandRegRead",63))



end


    
end
