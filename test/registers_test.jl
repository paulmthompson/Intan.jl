module Registers_Test

using Intan

if VERSION > v"0.7-"
    using Test
else
    using Base.Test
end

#Create command list
r=Intan.CreateRHD2000Registers(Float64(20000))



    #Sample Rate
    @test r.sampleRate == 20000

    #Register 0
    @test r.adcReferenceBw == 3
    @test r.ampVrefEnable == 1
    @test r.adcComparatorBias == 3
    @test r.adcComparatorSelect == 2

    #Register 1
    @test r.vddSenseEnable == 1

    #Register 2

    #Register 3
    @test r.tempS1 == 0
    @test r.tempS2 == 0
    @test r.tempEn == 0
    @test r.digOutHiZ == 1

    #Register 4
    @test r.weakMiso == 1
    @test r.twosComp == 0

    @test r.absMode == 0
    @test r.dspEn == 1
    @test r.dspCutoffFreq == 3

    #Register 5
    @test r.zcheckDacPower == 0
    @test r.zcheckLoad == 0
    @test r.zcheckScale == 0x00
    @test r.zcheckConnAll == 0
    @test r.zcheckSelPol == 0
    @test r.zcheckEn == 0

    #Register 7
    @test r.zcheckSelect == 0

    #Register 8-13
    @test r.offChipRH1 == 0
    @test r.offChipRH2 == 0
    @test r.offChipRL == 0
    @test r.adcAux1En == 1
    @test r.adcAux2En == 1
    @test r.adcAux3En == 1

    @test r.aPwr == ones(Int32,64)



#No ADC calibration
r=Intan.CreateRHD2000Registers(Float64(20000))
commandList=Intan.createCommandListRegisterConfig(zeros(Int32,1),false,r)


    #Is this correct?
    @test length(commandList) == 60


#No ADC calibration
r=Intan.CreateRHD2000Registers(Float64(20000))
commandList=Intan.createCommandListRegisterConfig(zeros(Int32,1),true,r)


    @test length(commandList) == 60



end
