module Registers_Test

using FactCheck, Intan

#Create command list
r=Intan.CreateRHD2000Registers(Float64(20000))

facts() do

    #Sample Rate
    @fact r.sampleRate --> 20000

    #Register 0
    @fact r.adcReferenceBw --> 3
    @fact r.ampVrefEnable --> 1
    @fact r.adcComparatorBias --> 3
    @fact r.adcComparatorSelect --> 2

    #Register 1
    @fact r.vddSenseEnable --> 1

    #Register 2

    #Register 3
    @fact r.tempS1 --> 0
    @fact r.tempS2 --> 0
    @fact r.tempEn --> 0
    @fact r.digOutHiZ --> 1

    #Register 4
    @fact r.weakMiso --> 1
    @fact r.twosComp --> 0

    @fact r.absMode --> 0
    @fact r.dspEn --> 1
    @fact r.dspCutoffFreq --> 3

    #Register 5
    @fact r.zcheckDacPower --> 0
    @fact r.zcheckLoad --> 0
    @fact r.zcheckScale --> 0x00
    @fact r.zcheckConnAll --> 0
    @fact r.zcheckSelPol --> 0
    @fact r.zcheckEn --> 0

    #Register 7
    @fact r.zcheckSelect --> 0

    #Register 8-13
    @fact r.offChipRH1 --> 0
    @fact r.offChipRH2 --> 0
    @fact r.offChipRL --> 0
    @fact r.adcAux1En --> 1
    @fact r.adcAux2En --> 1
    @fact r.adcAux3En --> 1

    @fact r.aPwr --> ones(Int32,64)
    
end

#No ADC calibration
r=Intan.CreateRHD2000Registers(Float64(20000))
commandList=Intan.createCommandListRegisterConfig(zeros(Int32,1),false,r)

facts() do
    #Is this correct?
    @fact length(commandList) --> 60
end

#No ADC calibration
r=Intan.CreateRHD2000Registers(Float64(20000))
commandList=Intan.createCommandListRegisterConfig(zeros(Int32,1),true,r)

facts() do
    @fact length(commandList) --> 60
end


end
