
module rhd2000evalboard

export open_board, uploadFpgaBitfile, initialize_board

const mylib="/home/nicolelislab/toolbox/DataAcq/libokFrontPanel.so"
const myfile="/home/nicolelislab/neural-analysis-toolbox/DataAcq/API/main.bit"

USB_BUFFER_SIZE = 2400000
RHYTHM_BOARD_ID = 500
MAX_NUM_DATA_STREAMS = 8
FIFO_CAPACITY_WORDS = 67108864

WireInResetRun = 0x00
WireInMaxTimeStepLsb = 0x01
WireInMaxTimeStepMsb = 0x02
WireInDataFreqPll = 0x03
WireInMisoDelay = 0x04
WireInCmdRamAddr = 0x05
WireInCmdRamBank = 0x06
WireInCmdRamData = 0x07
WireInAuxCmdBank1 = 0x08
WireInAuxCmdBank2 = 0x09
WireInAuxCmdBank3 = 0x0a
WireInAuxCmdLength1 = 0x0b
WireInAuxCmdLength2 = 0x0c
WireInAuxCmdLength3 = 0x0d
WireInAuxCmdLoop1 = 0x0e
WireInAuxCmdLoop2 = 0x0f
WireInAuxCmdLoop3 = 0x10
WireInLedDisplay = 0x11
WireInDataStreamSel1234 = 0x12
WireInDataStreamSel5678 = 0x13
WireInDataStreamEn = 0x14
WireInTtlOut = 0x15
WireInDacSource1 = 0x16
WireInDacSource2 = 0x17
WireInDacSource3 = 0x18
WireInDacSource4 = 0x19
WireInDacSource5 = 0x1a
WireInDacSource6 = 0x1b
WireInDacSource7 = 0x1c
WireInDacSource8 = 0x1d
WireInDacManual = 0x1e
WireInMultiUse = 0x1f

TrigInDcmProg = 0x40
TrigInSpiStart = 0x41
TrigInRamWrite = 0x42
TrigInDacThresh = 0x43
TrigInDacHpf = 0x44
TrigInExtFastSettle = 0x45
TrigInExtDigOut = 0x46

WireOutNumWordsLsb = 0x20
WireOutNumWordsMsb = 0x21
WireOutSpiRunning = 0x22
WireOutTtlIn = 0x23
WireOutDataClkLocked = 0x24
WireOutBoardMode = 0x25
WireOutBoardId = 0x3e
WireOutBoardVersion = 0x3f

PipeOutData = 0xa0

PortA1 = 0
PortA2 = 1
PortB1 = 2
PortB2 = 3
PortC1 = 4
PortC2 = 5
PortD1 = 6
PortD2 = 7
PortA1Ddr = 8
PortA2Ddr = 9
PortB1Ddr = 10
PortB2Ddr = 11
PortC1Ddr = 12
PortC2Ddr = 13
PortD1Ddr = 14
PortD2Ddr = 15

sampleRate=30000

function open_board()

    for i=1:MAX_NUM_DATA_STREAMS
        dataStreamEnabled[i]=0
    end
     
    #make device
    x=ccall((:okFrontPanel_Construct, mylib), Ptr{Void}, ())
    println("Constructed")

    nDevices=ccall((:okFrontPanel_GetDeviceCount,mylib), Int, (Ptr{Void},), x) 
    println("Found " ,nDevices, " Opal Kelly device(s)")

    #Get Serial Number (I'm assuing there is only one device)
    serialnumber=ccall((:okFrontPanel_GetDeviceListSerial,mylib), Void, (Ptr{Void}, Int, String), x, 0,"")
    println("Serial number is ", serialnumber)
    
    #Open by serial 
    ccall((:okFrontPanel_OpenBySerial, mylib), Cint, (Ptr{Void},String),x,serialnumber)

    #configure on-board PLL
    ccall((:okFrontPanel_LoadDefaultPLLConfiguration,mylib), Cint, (Ptr{Void},),x)

    return x

end

function uploadFpgaBitfile();  

    #upload configuration file
    ccall((:okFrontPanel_ConfigureFPGA,mylib),Cint,(Ptr{Void},String),x,myfile)

    #Check if FrontPanel Support is enabled
    ccall((:okFrontPanel_IsFrontPanelEnabled,mylib),Bool,(Ptr{Void},),x)

    #Update Wireouts
    ccall((:okFrontPanel_UpdateWireOuts,mylib),Void,(Ptr{Void},),x)
    
    #Get BoardID

    #Get Board Version

end

function initialize_board()

    resetBoard()
    setSampleRate(30000)
    selectAuxCommandBank("PortA","AuxCmd1", 0)
    selectAuxCommandBank("PortB", "AuxCmd1", 0)
    selectAuxCommandBank("PortC", "AuxCmd1", 0)
    selectAuxCommandBank("PortD", "AuxCmd1", 0)
    selectAuxCommandBank("PortA", "AuxCmd2", 0)
    selectAuxCommandBank("PortB", "AuxCmd2", 0)
    selectAuxCommandBank("PortC", "AuxCmd2", 0)
    selectAuxCommandBank("PortD", "AuxCmd2", 0)
    selectAuxCommandBank("PortA", "AuxCmd3", 0)
    selectAuxCommandBank("PortB", "AuxCmd3", 0)
    selectAuxCommandBank("PortC", "AuxCmd3", 0)
    selectAuxCommandBank("PortD", "AuxCmd3", 0)
    selectAuxCommandLength("AuxCmd1", 0, 0)
    selectAuxCommandLength("AuxCmd2", 0, 0)
    selectAuxCommandLength("AuxCmd3", 0, 0)

    setContinuousRunMode(true)
    
    setMaxTimeStep(4294967295) #4294967395 == (2^32 - 1)

    setCableLengthFeet("PortA", 3.0)  # assume 3 ft cables
    setCableLengthFeet("PortB", 3.0)
    setCableLengthFeet("PortC", 3.0)
    setCableLengthFeet("PortD", 3.0)

    setDspSettle(false);

    setDataSource(0, PortA1)
    setDataSource(1, PortB1)
    setDataSource(2, PortC1)
    setDataSource(3, PortD1)
    setDataSource(4, PortA2)
    setDataSource(5, PortB2)
    setDataSource(6, PortC2)
    setDataSource(7, PortD2)

    #remember that julia indexes with 1's instead of 0's to start an array
    enableDataStream(0, true)

    for i=1:MAX_NUM_DATA_STREAMS
        enableDataStream(i,false)
    end

    clearTtlOut()

    enableDac(0, false)
    enableDac(1, false)
    enableDac(2, false)
    enableDac(3, false)
    enableDac(4, false)
    enableDac(5, false)
    enableDac(6, false)
    enableDac(7, false)
    selectDacDataStream(0, 0)
    selectDacDataStream(1, 0)
    selectDacDataStream(2, 0)
    selectDacDataStream(3, 0)
    selectDacDataStream(4, 0)
    selectDacDataStream(5, 0)
    selectDacDataStream(6, 0)
    selectDacDataStream(7, 0)
    selectDacDataChannel(0, 0)
    selectDacDataChannel(1, 0)
    selectDacDataChannel(2, 0)
    selectDacDataChannel(3, 0)
    selectDacDataChannel(4, 0)
    selectDacDataChannel(5, 0)
    selectDacDataChannel(6, 0)
    selectDacDataChannel(7, 0)

    setDacManual(32768)    # midrange value = 0 V

    setDacGain(0)
    setAudioNoiseSuppress(0)

    setTtlMode(1)   # Digital outputs 0-7 are DAC comparators; 8-15 under manual control

    setDacThreshold(0, 32768, true)
    setDacThreshold(1, 32768, true)
    setDacThreshold(2, 32768, true)
    setDacThreshold(3, 32768, true)
    setDacThreshold(4, 32768, true)
    setDacThreshold(5, 32768, true)
    setDacThreshold(6, 32768, true)
    setDacThreshold(7, 32768, true)

    enableExternalFastSettle(false)
    setExternalFastSettleChannel(0)

    enableExternalDigOut("PortA", false)
    enableExternalDigOut("PortB", false)
    enableExternalDigOut("PortC", false)
    enableExternalDigOut("PortD", false)
    setExternalDigOutChannel("PortA", 0)
    setExternalDigOutChannel("PortB", 0)
    setExternalDigOutChannel("PortC", 0)
    setExternalDigOutChannel("PortD", 0)
       
end

function resetBoard()

    ccall((:okFrontPanel_SetWireInValue,mylib),Cint,(Ptr{Void},Int,Culong,Culong),x,WireInResetRun,0x01,0x01)
    ccall((:okFrontPanel_UpdateWireIns,mylib),Cint,(Ptr{Void},),x)
    ccall((:okFrontPanel_SetWireInValue,mylib),Cint,(Ptr{Void},Int,Culong,Culong),x,WireInResetRun,0x00,0x01)
    ccall((:okFrontPanel_UpdateWireIns,mylib),Cint,(Ptr{Void},),x)

end

function setSampleRate(newSampleRate)

    if newSampleRate==1000
        M=7
        D=125
    elseif newSampleRate==1250
        M=7
        D=125
    elseif newSampleRate==1500
        M=21
        D=250
    elseif newSampleRate==2000
        M=14
        D=125
    elseif newSampleRate==2500
        M=35
        D=250
    elseif newSampleRate==3000
        M=21
        D=125
    elseif newSampleRate==3333
        M=14
        D=75
    elseif newSampleRate==4000
        M=28
        D=125
    elseif newSampleRate==5000
        M=7
        D=25
    elseif newSampleRate==6250
        M=7
        D=20
    elseif newSampleRate==8000
        M=112
        D=250
    elseif newSampleRate==10000
        M=14
        D=25
    elseif newSampleRate==12500
        M=7
        D=10
    elseif newSampleRate==15000
        M=21
        D=25
    elseif newSampleRate==20000
        M=28
        D=25
    elseif newSampleRate==25000
        M=35
        D=25
    elseif newSampleRate==30000
        M=42
        D=25
    else
    end
  
    sampleRate=newSampleRate

    #Wait for DcmProgDone==1 before reprogramming clock synthesizer
    while (isDcmProgDone()==false)   
    end
   
    #Reprogram clock synthesizer
    ccall((:okFrontPanel_SetWireInValue,mylib),Cint,(Ptr{Void},Int,Culong,Culong),x,WireInDataFreqPll,(256 * M + D))    
    ccall((:okFrontPanel_UpdateWireIns,mylib),Cint,(Ptr{Void},),x)
    ccall((:okFrontPanel_ActivateTriggerIn,mylib),Cint,(Ptr{Void},Int,Int),x,TrigInDcmProg,0)
    
    #Wait for DataClkLocked = 1 before allowing data acquisition to continue
    while (isDataClockLocked() == false)
    end
                 
end

function getSampleRate()
    return sampleRate
end


function isDcmProgDone()

    ccall((:okFrontPanel_UpdateWireOuts,mylib),Void,(Ptr{Void},),x)
    value = ccall((:okFrontPanel_GetWireOutValue,mylib),Culong,(Ptr{Void},Int),x,WireOutDataClkLocked)

    #not sure how to change this return
    return ((value & 0x0002) > 1)

end

function isDataClockLocked()

    ccall((:okFrontPanel_UpdateWireOuts,mylib),Void,(Ptr{Void},),x)
    value = ccall((:okFrontPanel_GetWireOutValue,mylib),Culong,(Ptr{Void},Int),x,WireOutDataClkLocked)

    #not sure how to change this return
    return ((value & 0x0001) > 1)

end

function selectAuxCommandBank(port, commandslot, bank)

    #Error checking goes here


    if port=="PortA"
        bitShift==0
    elseif port=="PortB"
        bitShift==4
    elseif port=="PortC"
        bitShift==8
    elseif port=="PortD"
        bitShift==12
    end

    if commandslot=="AuxCmd1"
        ccall((:okFrontPanel_SetWireInValue,mylib),Cint,(Ptr{Void},Int,Culong,Culong),x,WireInAuxCmdBank1,(bank<<bitShift),(0x000f<<bitShift))  
    elseif commandslot=="AuxCmd2"
        ccall((:okFrontPanel_SetWireInValue,mylib),Cint,(Ptr{Void},Int,Culong,Culong),x,WireInAuxCmdBank2,(bank<<bitShift),(0x000f<<bitShift)) 
    elseif commandslot=="AuxCmd3"
        ccall((:okFrontPanel_SetWireInValue,mylib),Cint,(Ptr{Void},Int,Culong,Culong),x,WireInAuxCmdBank3,(bank<<bitShift),(0x000f<<bitShift)) 
    end

    ccall((:okFrontPanel_UpdateWireIns,mylib),Cint,(Ptr{Void},),x)

end

function selectAuxCommandLength(commandslot,loopIndex,endIndex)
    #Error checking goes here

    if commandslot=="AuxCmd1"
        ccall((:okFrontPanel_SetWireInValue,mylib),Cint,(Ptr{Void},Int,Culong,Culong),x,WireInAuxCmdLoop1,loopIndex)
        ccall((:okFrontPanel_SetWireInValue,mylib),Cint,(Ptr{Void},Int,Culong,Culong),x,WireInAuxCmdLength1,endIndex)
    elseif commandslot=="AuxCmd2"
        ccall((:okFrontPanel_SetWireInValue,mylib),Cint,(Ptr{Void},Int,Culong,Culong),x,WireInAuxCmdLoop2,loopIndex)
        ccall((:okFrontPanel_SetWireInValue,mylib),Cint,(Ptr{Void},Int,Culong,Culong),x,WireInAuxCmdLength2,endIndex)
    elseif commandslot=="AuxCmd3"
        ccall((:okFrontPanel_SetWireInValue,mylib),Cint,(Ptr{Void},Int,Culong,Culong),x,WireInAuxCmdLoop3,loopIndex)
        ccall((:okFrontPanel_SetWireInValue,mylib),Cint,(Ptr{Void},Int,Culong,Culong),x,WireInAuxCmdLength3,endIndex)
    end

    ccall((:okFrontPanel_UpdateWireIns,mylib),Cint,(Ptr{Void},),x)
    
end

function setContinuousRunMode(continuousMode)
    if continuousMode
        ccall((:okFrontPanel_SetWireInValue,mylib),Cint,(Ptr{Void},Int,Culong,Culong),x,WireInResetRun,0x02,0x02)
    else
        ccall((:okFrontPanel_SetWireInValue,mylib),Cint,(Ptr{Void},Int,Culong,Culong),x,WireInResetRun,0x00,0x02)
    end

    ccall((:okFrontPanel_UpdateWireIns,mylib),Cint,(Ptr{Void},),x)

end

function setMaxTimeStep(maxTimeStep)
    
    maxTimeStepLsb = maxTimeStep & 0x000fff
    maxTimeStepMsb = maxTimeStep & 0xffff0000

    ccall((:okFrontPanel_SetWireInValue,mylib),Cint,(Ptr{Void},Int,Culong,Culong),x,WireInMaxTimeStepLsb,maxTimeStepLsb)
    ccall((:okFrontPanel_SetWireInValue,mylib),Cint,(Ptr{Void},Int,Culong,Culong),x,WireInMaxTimeStepMsb,maxTimeStepMsb >> 16)

    ccall((:okFrontPanel_UpdateWireIns,mylib),Cint,(Ptr{Void},),x)
    
end

function setCableLengthFeet(port, lengthInFeet)
    setCableLengthMeters(port, .3048 * lengthInFeet)
end

function setCableLengthMeters(port, lengthInMeters)

    speedOfLight = 299792458.0
    xilinxLvdsOutputDelay=1.9e-9
    xilinxLvdsInputDelay=1.4e-9
    rhd2000Delay=9.0e-9
    misoSettleTime=6.7e-9

    tStep=1.0 / (2800.0 * getSampleRate())

    cableVelocity=.555 * speedOfLight

    distance = 2.0 * lengthInMeters

    timeDelay = (distance / cableVelocity) + xilinxLvdsOutputDelay + rhd2000Delay + xilinxLvdsInputDelay + misoSettleTime

    delay = Int(floor(((timeDelay / tStep) + 1.0) +0.5))

    if delay <1
        delay=1
    end

    setCableDelay(port, delay)
end

function setCableDelay(port, delay)
    #error checking goes here

    if delay<0
        delay=0
    elseif delay>15
        delay=15
    end

    #here i should update the bit shift int and cableDelay vector of ints appropriately. I have no idea what the cableDelay vector does

    if port=="PortA"
        bitShift=0;
    elseif port=="PortB"
        bitShift=4
    elseif port=="PortC"
        bitShift=8
    elseif port=="PortD"
        bitShift=12
    end

    ccall((:okFrontPanel_SetWireInValue,mylib),Cint,(Ptr{Void},Int,Culong,Culong),x,WireInMisoDelay,delay << bitShift, 0x000f << bitShift)

    ccall((:okFrontPanel_UpdateWireIns,mylib),Cint,(Ptr{Void},),x)
    
end

function setDspSettle(enabled)
    
    ccall((:okFrontPanel_SetWireInValue,mylib),Cint,(Ptr{Void},Int,Culong,Culong),x,WireInResetRun,(enabled ? 0x04 : 0x00), 0x04)

    ccall((:okFrontPanel_UpdateWireIns,mylib),Cint,(Ptr{Void},),x)

end

function setDataSource(stream, dataSource)

    #error checking goes here

    if stream==0
        endPoint=WireInDataStreamSel1234
        bitShift=0
    elseif stream==1
        endPoint=WireInDataStreamSel1234
        bitShift=4
    elseif stream==2
        endPoint=WireInDataStreamSel1234
        bitShift=8
    elseif stream==3
        endPoint=WireInDataStreamSel1234
        bitShift=12
    elseif stream==4
        endPoint=WireInDataStreamSel5678
        bitShift=0
    elseif stream==5
        endPoint=WireInDataStreamSel5678
        bitShift=4
    elseif stream==6
        endPoint=WireInDataStreamSel5678
        bitShift=8
    elseif stream==7
        endPoint=WireInDataStreamSel5678
        bitShift=12
    end

    ccall((:okFrontPanel_SetWireInValue,mylib),Cint,(Ptr{Void},Int,Culong,Culong),x,endPoint, dataSource << bitShift, 0x000f << bitShift)

    ccall((:okFrontPanel_UpdateWireIns,mylib),Cint,(Ptr{Void},),x)

end

function enableDataStream(stream, enabled)

    #error checking goes here

    if enabled
        if dataStreamEnabled[stream+1] == 0
            ccall((:okFrontPanel_SetWireInValue,mylib),Cint,(Ptr{Void},Int,Culong,Culong),x,WireInDataStreamEn, 0x0001 << stream, 0x0001 << stream)
            ccall((:okFrontPanel_UpdateWireIns,mylib),Cint,(Ptr{Void},),x)
            dataStreamEnabled[stream+1] = 1;
            numDataStreams=numDataStreams+1;
        end
    else
        if dataStreamEnabled[stream+1] == 1
            ccall((:okFrontPanel_SetWireInValue,mylib),Cint,(Ptr{Void},Int,Culong,Culong),x,WireInDataStreamEn, 0x0000 << stream, 0x0001 << stream)
            ccall((:okFrontPanel_UpdateWireIns,mylib),Cint,(Ptr{Void},),x)
            dataStreamEnabled[stream+1] = 0;
            numDataStream=numDataStreams-1;
        end
    end
                
end

function enableDac(dacChannel, enabled)

    #error checking goes here

    if dacChannel == 0
        ccall((:okFrontPanel_SetWireInValue,mylib),Cint,(Ptr{Void},Int,Culong,Culong),x,WireInDacSource1, (enabled ? 0x0200 : 0x0000), 0x0200)
    elseif dacChannel == 1
        ccall((:okFrontPanel_SetWireInValue,mylib),Cint,(Ptr{Void},Int,Culong,Culong),x,WireInDacSource2, (enabled ? 0x0200 : 0x0000), 0x0200)
    elseif dacChannel == 2
        ccall((:okFrontPanel_SetWireInValue,mylib),Cint,(Ptr{Void},Int,Culong,Culong),x,WireInDacSource3, (enabled ? 0x0200 : 0x0000), 0x0200)
    elseif dacChannel == 3
        ccall((:okFrontPanel_SetWireInValue,mylib),Cint,(Ptr{Void},Int,Culong,Culong),x,WireInDacSource4, (enabled ? 0x0200 : 0x0000), 0x0200)
    elseif dacChannel == 4
        ccall((:okFrontPanel_SetWireInValue,mylib),Cint,(Ptr{Void},Int,Culong,Culong),x,WireInDacSource5, (enabled ? 0x0200 : 0x0000), 0x0200)
    elseif dacChannel == 5
        ccall((:okFrontPanel_SetWireInValue,mylib),Cint,(Ptr{Void},Int,Culong,Culong),x,WireInDacSource6, (enabled ? 0x0200 : 0x0000), 0x0200)
    elseif dacChannel == 6
        ccall((:okFrontPanel_SetWireInValue,mylib),Cint,(Ptr{Void},Int,Culong,Culong),x,WireInDacSource7, (enabled ? 0x0200 : 0x0000), 0x0200)
    elseif dacChannel == 7
        ccall((:okFrontPanel_SetWireInValue,mylib),Cint,(Ptr{Void},Int,Culong,Culong),x,WireInDacSource8, (enabled ? 0x0200 : 0x0000), 0x0200)
    end

    ccall((:okFrontPanel_UpdateWireIns,mylib),Cint,(Ptr{Void},),x)

end

function selectDacDataStream(dacChannel, stream)
    #error checking goes here

    if dacChannel == 0
        ccall((:okFrontPanel_SetWireInValue,mylib),Cint,(Ptr{Void},Int,Culong,Culong),x,WireInDacSource1, stream << 5, 0x01e0)
    elseif dacChannel == 1
        ccall((:okFrontPanel_SetWireInValue,mylib),Cint,(Ptr{Void},Int,Culong,Culong),x,WireInDacSource2, stream << 5, 0x01e0)
    elseif dacChannel == 2
        ccall((:okFrontPanel_SetWireInValue,mylib),Cint,(Ptr{Void},Int,Culong,Culong),x,WireInDacSource3, stream << 5, 0x01e0)
    elseif dacChannel == 3
        ccall((:okFrontPanel_SetWireInValue,mylib),Cint,(Ptr{Void},Int,Culong,Culong),x,WireInDacSource4, stream << 5, 0x01e0)
    elseif dacChannel == 4
        ccall((:okFrontPanel_SetWireInValue,mylib),Cint,(Ptr{Void},Int,Culong,Culong),x,WireInDacSource5, stream << 5, 0x01e0)
    elseif dacChannel == 5
        ccall((:okFrontPanel_SetWireInValue,mylib),Cint,(Ptr{Void},Int,Culong,Culong),x,WireInDacSource6, stream << 5, 0x01e0)
    elseif dacChannel == 6
        ccall((:okFrontPanel_SetWireInValue,mylib),Cint,(Ptr{Void},Int,Culong,Culong),x,WireInDacSource7, stream << 5, 0x01e0)
    elseif dacChannel == 7
        ccall((:okFrontPanel_SetWireInValue,mylib),Cint,(Ptr{Void},Int,Culong,Culong),x,WireInDacSource8, stream << 5, 0x01e0)
    end

    ccall((:okFrontPanel_UpdateWireIns,mylib),Cint,(Ptr{Void},),x)
        
end

function selectDacDataChannel(dacChannel, dataChannel)
    #error checking goes here

    if dacChannel == 0
        ccall((:okFrontPanel_SetWireInValue,mylib),Cint,(Ptr{Void},Int,Culong,Culong),x,WireInDacSource1, dataChannel << 0, 0x001f)
    elseif dacChannel == 1
        ccall((:okFrontPanel_SetWireInValue,mylib),Cint,(Ptr{Void},Int,Culong,Culong),x,WireInDacSource2, dataChannel << 0, 0x001f)
    elseif dacChannel == 2
        ccall((:okFrontPanel_SetWireInValue,mylib),Cint,(Ptr{Void},Int,Culong,Culong),x,WireInDacSource3, dataChannel << 0, 0x001f)
    elseif dacChannel == 3
        ccall((:okFrontPanel_SetWireInValue,mylib),Cint,(Ptr{Void},Int,Culong,Culong),x,WireInDacSource4, dataChannel << 0, 0x001f)
    elseif dacChannel == 4
        ccall((:okFrontPanel_SetWireInValue,mylib),Cint,(Ptr{Void},Int,Culong,Culong),x,WireInDacSource5, dataChannel << 0, 0x001f)
    elseif dacChannel == 5
        ccall((:okFrontPanel_SetWireInValue,mylib),Cint,(Ptr{Void},Int,Culong,Culong),x,WireInDacSource6, dataChannel << 0, 0x001f)
    elseif dacChannel == 6
        ccall((:okFrontPanel_SetWireInValue,mylib),Cint,(Ptr{Void},Int,Culong,Culong),x,WireInDacSource7, dataChannel << 0, 0x001f)
    elseif dacChannel == 7
        ccall((:okFrontPanel_SetWireInValue,mylib),Cint,(Ptr{Void},Int,Culong,Culong),x,WireInDacSource8, dataChannel << 0, 0x001f)
    end

    ccall((:okFrontPanel_UpdateWireIns,mylib),Cint,(Ptr{Void},),x)
    
end

function setDacManual(value)
    #error checking goes here

    ccall((:okFrontPanel_SetWireInValue,mylib),Cint,(Ptr{Void},Int,Culong,Culong),x,WireInDacManual, value)
    ccall((:okFrontPanel_UpdateWireIns,mylib),Cint,(Ptr{Void},),x)
    
end

function setDacGain(gain)
    #error checking goes here
    
    ccall((:okFrontPanel_SetWireInValue,mylib),Cint,(Ptr{Void},Int,Culong,Culong),x,WireInResetRun, gain << 13, 0xe000)
    ccall((:okFrontPanel_UpdateWireIns,mylib),Cint,(Ptr{Void},),x)
    
end

function setAudioNoiseSuppress(noiseSuppress)
    #error checking goes here

    ccall((:okFrontPanel_SetWireInValue,mylib),Cint,(Ptr{Void},Int,Culong,Culong),x,WireInResetRun, noiseSuppress << 6, 0x1fc0)
    ccall((:okFrontPanel_UpdateWireIns,mylib),Cint,(Ptr{Void},),x)

end

function setTtlMode(mode)
    #error checking goes here

    ccall((:okFrontPanel_SetWireInValue,mylib),Cint,(Ptr{Void},Int,Culong,Culong),x,WireInResetRun, mode << 3, 0x0008)

    ccall((:okFrontPanel_UpdateWireIns,mylib),Cint,(Ptr{Void},),x)

end


function setDacThreshold(dacChannel, threshold, trigPolarity)

    #error checking goes here

    #Set threshold level
    ccall((:okFrontPanel_SetWireInValue,mylib),Cint,(Ptr{Void},Int,Culong,Culong),x,WireInMultiUse,threshold)
    ccall((:okFrontPanel_UpdateWireIns,mylib),Cint,(Ptr{Void},),x)
    ccall((:okFrontPanel_ActivateTriggerIn, mylib), Cint,(Ptr{Void},Int,Int),x,TrigInDacThresh, dacChannel)

    #Set threshold polarity

    ccall((:okFrontPanel_SetWireInValue,mylib),Cint,(Ptr{Void},Int,Culong,Culong),x,WireInMultiUse, (trigPolarity ? 1 :0))
    ccall((:okFrontPanel_UpdateWireIns,mylib),Cint,(Ptr{Void},),x)
    ccall((:okFrontPanel_ActivateTriggerIn, mylib), Cint,(Ptr{Void},Int,Int),x,TrigInDacThresh, dacChannel+8)


end

function enableExternalFastSettle(enable)
    
    ccall((:okFrontPanel_SetWireInValue,mylib),Cint,(Ptr{Void},Int,Culong,Culong),x,WireInMultiUse, enable ? 1 : 0)
    ccall((:okFrontPanel_UpdateWireIns,mylib),Cint,(Ptr{Void},),x)
    ccall((:okFrontPanel_ActivateTriggerIn, mylib), Cint,(Ptr{Void},Int,Int),x,TrigInExtFastSettle,0)

end

function setExternalFastSettleChannel(channel)

    #error checking goes here

        ccall((:okFrontPanel_SetWireInValue,mylib),Cint,(Ptr{Void},Int,Culong,Culong),x,WireInMultiUse, channel)
    ccall((:okFrontPanel_UpdateWireIns,mylib),Cint,(Ptr{Void},),x)
    ccall((:okFrontPanel_ActivateTriggerIn, mylib), Cint,(Ptr{Void},Int,Int),x,TrigInExtFastSettle,1)
    
end

function enableExternalDigOut(port, enable)

    ccall((:okFrontPanel_SetWireInValue,mylib),Cint,(Ptr{Void},Int,Culong,Culong),x,WireInMultiUse, enable ? 1 : 0)
    ccall((:okFrontPanel_UpdateWireIns,mylib),Cint,(Ptr{Void},),x)

    if port=="PortA"
        ccall((:okFrontPanel_ActivateTriggerIn, mylib), Cint,(Ptr{Void},Int,Int),x,TrigInExtDigOut,0)
    elseif port=="PortB"
        ccall((:okFrontPanel_ActivateTriggerIn, mylib), Cint,(Ptr{Void},Int,Int),x,TrigInExtDigOut,1)
    elseif port=="PortC"
        ccall((:okFrontPanel_ActivateTriggerIn, mylib), Cint,(Ptr{Void},Int,Int),x,TrigInExtDigOut,2)
    elseif port=="PortD"
        ccall((:okFrontPanel_ActivateTriggerIn, mylib), Cint,(Ptr{Void},Int,Int),x,TrigInExtDigOut,3)
    end
     
end

function setExternalDigOutChannel(port channel)

    ccall((:okFrontPanel_SetWireInValue,mylib),Cint,(Ptr{Void},Int,Culong,Culong),x,WireInMultiUse, channel)
    ccall((:okFrontPanel_UpdateWireIns,mylib),Cint,(Ptr{Void},),x)

    if port=="PortA"
        ccall((:okFrontPanel_ActivateTriggerIn, mylib), Cint,(Ptr{Void},Int,Int),x,TrigInExtDigOut,4)
    elseif port=="PortB"
        ccall((:okFrontPanel_ActivateTriggerIn, mylib), Cint,(Ptr{Void},Int,Int),x,TrigInExtDigOut,5)
    elseif port=="PortC"
        ccall((:okFrontPanel_ActivateTriggerIn, mylib), Cint,(Ptr{Void},Int,Int),x,TrigInExtDigOut,6)
    elseif port=="PortD"
        ccall((:okFrontPanel_ActivateTriggerIn, mylib), Cint,(Ptr{Void},Int,Int),x,TrigInExtDigOut,7)
    end

end

function getTtlIn(ttlInArray)

    ccall((:okFrontPanel_UpdateWireOuts,mylib),Void,(Ptr{Void},),x)
    ttlIn=ccall((:okFrontPanel_GetWireOutValue,mylib),Culong,(Ptr{Void},Int),x,WireOutTtlIn)
    for i=1:16
        ttlInArray[i] = 0
        if (ttlIN & (1 << (i-1))) > 0
            ttlInArray[i] = 1
        end
    end
end

function setLedDisplay(ledArray)

    ledOut=0
    for i=1:8
        if ledArray[i]>0
            ledOut +=1 << i
        end
    end

    ccall((:okFrontPanel_SetWireInValue,mylib),Cint,(Ptr{Void},Int,Culong,Culong),x,WireInLedDisplay, ledOut)
    ccall((:okFrontPanel_UpdateWireIns,mylib),Cint,(Ptr{Void},),x)

end

function run()
    ccall((:okFrontPanel_ActivateTriggerIn, mylib), Cint,(Ptr{Void},Int,Int),x,TrigInSpiStart, 0)
end

end

