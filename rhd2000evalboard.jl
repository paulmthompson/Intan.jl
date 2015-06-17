
module rhd2000evalboard

using HDF5, SortSpikes, DistributedArrays, ExtractSpikes

export open_board, uploadFpgaBitfile, initialize_board, setSampleRate, setCableLengthFeet, setLedDisplay, setMaxTimeStep, setContinuousRunMode, runBoard, isRunning, numWordsInFifo,flushBoard, enableDataStream, readDataBlocks, queueToFile, setDataSource, selectAuxCommandLength, selectAuxCommandBank, uploadCommandList, ReadFromPipeOut

#Constant parameters

#CHANGE ME
const mylib="/home/nicolelislab/Intan.jl/libokFrontPanel.so"
const myfile="/home/nicolelislab/Intan.jl/main.bit"

const USB_BUFFER_SIZE = 2400000
const RHYTHM_BOARD_ID = 500
const MAX_NUM_DATA_STREAMS = 8
const FIFO_CAPACITY_WORDS = 67108864
const SAMPLES_PER_DATA_BLOCK = 600

const WireInResetRun = 0x00
const WireInMaxTimeStepLsb = 0x01
const WireInMaxTimeStepMsb = 0x02
const WireInDataFreqPll = 0x03
const WireInMisoDelay = 0x04
const WireInCmdRamAddr = 0x05
const WireInCmdRamBank = 0x06
const WireInCmdRamData = 0x07
const WireInAuxCmdBank1 = 0x08
const WireInAuxCmdBank2 = 0x09
const WireInAuxCmdBank3 = 0x0a
const WireInAuxCmdLength1 = 0x0b
const WireInAuxCmdLength2 = 0x0c
const WireInAuxCmdLength3 = 0x0d
const WireInAuxCmdLoop1 = 0x0e
const WireInAuxCmdLoop2 = 0x0f
const WireInAuxCmdLoop3 = 0x10
const WireInLedDisplay = 0x11
const WireInDataStreamSel1234 = 0x12
const WireInDataStreamSel5678 = 0x13
const WireInDataStreamEn = 0x14
const WireInTtlOut = 0x15
const WireInDacSource1 = 0x16
const WireInDacSource2 = 0x17
const WireInDacSource3 = 0x18
const WireInDacSource4 = 0x19
const WireInDacSource5 = 0x1a
const WireInDacSource6 = 0x1b
const WireInDacSource7 = 0x1c
const WireInDacSource8 = 0x1d
const WireInDacManual = 0x1e
const WireInMultiUse = 0x1f

const TrigInDcmProg = 0x40
const TrigInSpiStart = 0x41
const TrigInRamWrite = 0x42
const TrigInDacThresh = 0x43
const TrigInDacHpf = 0x44
const TrigInExtFastSettle = 0x45
const TrigInExtDigOut = 0x46

const WireOutNumWordsLsb = 0x20
const WireOutNumWordsMsb = 0x21
const WireOutSpiRunning = 0x22
const WireOutTtlIn = 0x23
const WireOutDataClkLocked = 0x24
const WireOutBoardMode = 0x25
const WireOutBoardId = 0x3e
const WireOutBoardVersion = 0x3f

const PipeOutData = 0xa0

#For 32 channel amps
const PortA1 = 0
const PortA2 = 1
const PortB1 = 2
const PortB2 = 3
const PortC1 = 4
const PortC2 = 5
const PortD1 = 6
const PortD2 = 7

#For 64 channel amps
const PortA1Ddr = 8
const PortA2Ddr = 9
const PortB1Ddr = 10
const PortB2Ddr = 11
const PortC1Ddr = 12
const PortC2Ddr = 13
const PortD1Ddr = 14
const PortD2Ddr = 15

#Variables that get modified

global sampleRate=30000

global numDataStreams=0

global dataStreamEnabled=zeros(Int,1,MAX_NUM_DATA_STREAMS)

const y = ccall((:okFrontPanel_Construct, mylib), Ptr{Void}, ())

function open_board()

    println("Scanning USB for Opal Kelly devices...")
    nDevices=ccall((:okFrontPanel_GetDeviceCount,mylib), Int, (Ptr{Void},), y) 
    println("Found ", nDevices, " Opal Kelly device(s)")

    #Get Serial Number (I'm assuing there is only one device)
    serial=Array(Uint8,11)
    ccall((:okFrontPanel_GetDeviceListSerial,mylib), Int32, (Ptr{Void}, Int, Ptr{Uint8}), y, 0,serial)
    serial[end]=0
    serialnumber=bytestring(pointer(serial))
    println("Serial number of device 0 is ", serialnumber)
    
    #Open by serial 
    if (ccall((:okFrontPanel_OpenBySerial, mylib), Cint, (Ptr{Void},Ptr{Uint8}),y,serialnumber)!=0)
        println("Device could not be opened. Is one connected?")
        return -2
    end
    
    #configure on-board PLL
    ccall((:okFrontPanel_LoadDefaultPLLConfiguration,mylib), Cint, (Ptr{Void},),y)

    return 1

end

function uploadFpgaBitfile()

    #upload configuration file
    errorcode=ccall((:okFrontPanel_ConfigureFPGA,mylib),Cint,(Ptr{Void},Ptr{Uint8}),y,myfile)

    #error checking goes here
    if errorcode==0
        println("FPGA configuration loaded.")
    else
        println("FPGA configuration failed.")
    end
    
    
    #Check if FrontPanel Support is enabled
    ccall((:okFrontPanel_IsFrontPanelEnabled,mylib),Bool,(Ptr{Void},),y)

    UpdateWireOuts()
    
    boardId = GetWireOutValue(WireOutBoardId)
    boardVersion = GetWireOutValue(WireOutBoardVersion)
    if (boardId != RHYTHM_BOARD_ID)
        println("FPGA configuration does not support Rythm. Incorrect board ID: ", boardId)
    else
        println("Rhythm configuration file successfully loaded. Rhythm version number: ", boardVersion)
    end
    
end

function initialize_board()
  
    resetBoard()
    setSampleRate(30000)
    selectAuxCommandBank("PortA", "AuxCmd1", 0)
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

    setDspSettle(false)

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
    for i=1:(MAX_NUM_DATA_STREAMS-1)
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

    SetWireInValue(WireInResetRun, 0x01, 0x01)
    UpdateWireIns()
    SetWireInValue(WireInResetRun, 0x00, 0x01)
    UpdateWireIns()
    
end

function setSampleRate(newSampleRate::Int64)

    global sampleRate

    if newSampleRate==1000
        M=7
        D=125
    elseif newSampleRate==1250
        M=7
        D=100
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

    SetWireInValue(WireInDataFreqPll,(256 * convert(Culong,M) + convert(Culong,D)))
    UpdateWireIns()  
    ActivateTriggerIn(TrigInDcmProg,0)
   
    #Wait for DataClkLocked = 1 before allowing data acquisition to continue
    while (isDataClockLocked() == false)
    end
                 
end

function getSampleRate()

    global sampleRate
    
    return sampleRate
end


function isDcmProgDone()

    UpdateWireOuts()
    value=GetWireOutValue(WireOutDataClkLocked)

    return ((value & 0x0002) > 1)

end

function isDataClockLocked()

    UpdateWireOuts()
    value=GetWireOutValue(WireOutDataClkLocked)
    
    return ((value & 0x0001) > 0)

end

function uploadCommandList(commandList, auxCommandSlot, bank)

    #error checking goes here

    for i=1:length(commandList)

        SetWireInValue(WireInCmdRamData, commandList[i])
        SetWireInValue(WireInCmdRamAddr, i-1)
        SetWireInValue(WireInCmdRamBank, bank)
        UpdateWireIns()
        if auxCommandSlot == "AuxCmd1"
            ActivateTriggerIn(TrigInRamWrite,0)
        elseif auxCommandSlot == "AuxCmd2"
            ActivateTriggerIn(TrigInRamWrite,1)
        elseif auxCommandSlot == "AuxCmd3"
            ActivateTriggerIn(TrigInRamWrite,2)
        end
        
    end
    
end

function selectAuxCommandBank(port, commandslot, bank)

    #Error checking goes here


    if port=="PortA"
        bitShift=0
    elseif port=="PortB"
        bitShift=4
    elseif port=="PortC"
        bitShift=8
    elseif port=="PortD"
        bitShift=12
    end

    if commandslot=="AuxCmd1"
        SetWireInValue(WireInAuxCmdBank1,(bank<<bitShift),(0x000f<<bitShift))
    elseif commandslot=="AuxCmd2"
        SetWireInValue(WireInAuxCmdBank2,(bank<<bitShift),(0x000f<<bitShift))
    elseif commandslot=="AuxCmd3"
        SetWireInValue(WireInAuxCmdBank3,(bank<<bitShift),(0x000f<<bitShift))
    end

    UpdateWireIns()

end

function selectAuxCommandLength(commandslot,loopIndex,endIndex)
    
    #Error checking goes here

    if commandslot=="AuxCmd1"
        SetWireInValue(WireInAuxCmdLoop1,loopIndex)
        SetWireInValue(WireInAuxCmdLength1,endIndex)
    elseif commandslot=="AuxCmd2"
        SetWireInValue(WireInAuxCmdLoop2,loopIndex)
        SetWireInValue(WireInAuxCmdLength2,endIndex)
    elseif commandslot=="AuxCmd3"
        SetWireInValue(WireInAuxCmdLoop3,loopIndex)
        SetWireInValue(WireInAuxCmdLength3,endIndex)
    end

    UpdateWireIns()
    
end

function setContinuousRunMode(continuousMode)
    
    if continuousMode
        SetWireInValue(WireInResetRun,0x02,0x02)
    else
        SetWireInValue(WireInResetRun,0x00,0x02)
    end

    UpdateWireIns()

end

function setMaxTimeStep(maxTimeStep)

    maxTimeStep=convert(Uint32, maxTimeStep)
    
    maxTimeStepLsb = maxTimeStep & 0x0000ffff
    maxTimeStepMsb = maxTimeStep & 0xffff0000

    SetWireInValue(WireInMaxTimeStepLsb,maxTimeStepLsb)
    SetWireInValue(WireInMaxTimeStepMsb,(maxTimeStepMsb >> 16))
    UpdateWireIns()
    
end

function setCableLengthFeet(port, lengthInFeet::Float64)
    setCableLengthMeters(port, .3048 * lengthInFeet)
end

function setCableLengthMeters(port, lengthInMeters::Float64)

    speedOfLight = 299792458.0
    xilinxLvdsOutputDelay=1.9e-9
    xilinxLvdsInputDelay=1.4e-9
    rhd2000Delay=9.0e-9
    misoSettleTime=6.7e-9

    tStep=1.0 / (2800.0 * getSampleRate())

    cableVelocity=.555 * speedOfLight

    distance = 2.0 * lengthInMeters

    timeDelay = (distance / cableVelocity) + xilinxLvdsOutputDelay + rhd2000Delay + xilinxLvdsInputDelay + misoSettleTime

    delay = convert(Int32,floor(((timeDelay / tStep) + 1.0) +0.5))

    if delay < 1
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

    bitShift=convert(Int32, bitShift)
    
    SetWireInValue(WireInMisoDelay, delay << bitShift, 0x000f << bitShift)
    UpdateWireIns()
    
end

function setDspSettle(enabled)

    SetWireInValue(WireInResetRun, (enabled ? 0x04 : 0x00), 0x04)
    UpdateWireIns()

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

    bitShift=convert(Int32,bitShift)
    SetWireInValue(endPoint,(dataSource << bitShift), (0x000f << bitShift))
    UpdateWireIns()

end

function enableDataStream(stream::Int, enabled::Bool)

    global dataStreamEnabled
    global numDataStreams
    
    #error checking goes here

    stream=convert(Int32,stream)
    if enabled
        if dataStreamEnabled[stream+1] == 0
            SetWireInValue(WireInDataStreamEn,0x0001 << stream, 0x0001 << stream)
            UpdateWireIns()
            dataStreamEnabled[stream+1] = 1;
            numDataStreams=numDataStreams+1;
        end
    else
        if dataStreamEnabled[stream+1] == 1
            SetWireInValue(WireInDataStreamEn,0x0000 << stream, 0x0001 << stream)
            UpdateWireIns()
            dataStreamEnabled[stream+1] = 0;
            numDataStream=numDataStreams-1;
        end
    end
                
end

function enableDac(dacChannel::Int, enabled::Bool)

    #error checking goes here

    if dacChannel == 0
        SetWireInValue(WireInDacSource1,(enabled ? 0x0200 : 0x0000), 0x0200)
    elseif dacChannel == 1
        SetWireInValue(WireInDacSource2,(enabled ? 0x0200 : 0x0000), 0x0200)
    elseif dacChannel == 2
        SetWireInValue(WireInDacSource3,(enabled ? 0x0200 : 0x0000), 0x0200)
    elseif dacChannel == 3
        SetWireInValue(WireInDacSource4,(enabled ? 0x0200 : 0x0000), 0x0200)
    elseif dacChannel == 4
        SetWireInValue(WireInDacSource5,(enabled ? 0x0200 : 0x0000), 0x0200)
    elseif dacChannel == 5
        SetWireInValue(WireInDacSource6,(enabled ? 0x0200 : 0x0000), 0x0200)
    elseif dacChannel == 6
        SetWireInValue(WireInDacSource7,(enabled ? 0x0200 : 0x0000), 0x0200)
    elseif dacChannel == 7
        SetWireInValue(WireInDacSource8,(enabled ? 0x0200 : 0x0000), 0x0200)
    end

    UpdateWireIns()

end

function selectDacDataStream(dacChannel, stream)
    #error checking goes here

    
    if dacChannel == 0
         SetWireInValue(WireInDacSource1, stream << 5, 0x01e0)
    elseif dacChannel == 1
         SetWireInValue(WireInDacSource2, stream << 5, 0x01e0)
    elseif dacChannel == 2
         SetWireInValue(WireInDacSource3, stream << 5, 0x01e0)
    elseif dacChannel == 3
         SetWireInValue(WireInDacSource4, stream << 5, 0x01e0)
    elseif dacChannel == 4
         SetWireInValue(WireInDacSource5, stream << 5, 0x01e0)
    elseif dacChannel == 5
         SetWireInValue(WireInDacSource6, stream << 5, 0x01e0)
    elseif dacChannel == 6
         SetWireInValue(WireInDacSource7, stream << 5, 0x01e0)
    elseif dacChannel == 7
         SetWireInValue(WireInDacSource8, stream << 5, 0x01e0)
    end

    UpdateWireIns()
        
end

function selectDacDataChannel(dacChannel::Int, dataChannel)
    #error checking goes here

    if dacChannel == 0
        SetWireInValue(WireInDacSource1,dataChannel << 0, 0x001f)
    elseif dacChannel == 1
        SetWireInValue(WireInDacSource2,dataChannel << 0, 0x001f)
    elseif dacChannel == 2
        SetWireInValue(WireInDacSource3,dataChannel << 0, 0x001f)
    elseif dacChannel == 3
        SetWireInValue(WireInDacSource4,dataChannel << 0, 0x001f)
    elseif dacChannel == 4
        SetWireInValue(WireInDacSource5,dataChannel << 0, 0x001f)
    elseif dacChannel == 5
        SetWireInValue(WireInDacSource6,dataChannel << 0, 0x001f)
    elseif dacChannel == 6
        SetWireInValue(WireInDacSource7,dataChannel << 0, 0x001f)
    elseif dacChannel == 7
        SetWireInValue(WireInDacSource8,dataChannel << 0, 0x001f)
    end

    UpdateWireIns()
    
end

function setDacManual(value)
    #error checking goes here

    SetWireInValue(WireInDacManual,value)
    UpdateWireIns()
    
end

function setDacGain(gain)
    #error checking goes here

    
    SetWireInValue(WireInResetRun,gain << 13, 0xe000)
    UpdateWireIns()
    
end

function setAudioNoiseSuppress(noiseSuppress)
    #error checking goes here

    SetWireInValue(WireInResetRun, noiseSuppress << 6, 0x1fc0)
    UpdateWireIns()

end

function setTtlMode(mode)
    #error checking goes here

    SetWireInValue(WireInResetRun, mode << 3, 0x0008)
    UpdateWireIns()

end

function clearTtlOut()

    SetWireInValue(WireInTtlOut, 0x0000)
    UpdateWireIns()

end


function setDacThreshold(dacChannel, threshold, trigPolarity)

    #error checking goes here

    #Set threshold level
    SetWireInValue(WireInMultiUse,threshold)
    UpdateWireIns()
    ActivateTriggerIn(TrigInDacThresh, dacChannel)

    #Set threshold polarity
    SetWireInValue(WireInMultiUse, (trigPolarity ? 1 : 0))
    UpdateWireIns()
    ActivateTriggerIn(TrigInDacThresh, dacChannel+8)

end

function enableExternalFastSettle(enable)

    SetWireInValue(WireInMultiUse, (enable ? 1 : 0))
    UpdateWireIns()
    ActivateTriggerIn(TrigInExtFastSettle,0)

end

function setExternalFastSettleChannel(channel)

    #error checking goes here

    SetWireInValue(WireInMultiUse,channel)
    UpdateWireIns()
    ActivateTriggerIn(TrigInExtFastSettle,1)
  
end

function enableExternalDigOut(port, enable)

    SetWireInValue(WireInMultiUse, (enable ? 1 : 0))
    UpdateWireIns()

    if port=="PortA"
        ActivateTriggerIn(TrigInExtDigOut,0)
    elseif port=="PortB"
        ActivateTriggerIn(TrigInExtDigOut,1)
    elseif port=="PortC"
        ActivateTriggerIn(TrigInExtDigOut,2)
    elseif port=="PortD"
        ActivateTriggerIn(TrigInExtDigOut,3)
    end
     
end

function setExternalDigOutChannel(port, channel)

    SetWireInValue(WireInMultiUse,channel)
    UpdateWireIns()

    if port=="PortA"
        ActivateTriggerIn(TrigInExtDigOut,4)
    elseif port=="PortB"
        ActivateTriggerIn(TrigInExtDigOut,5)
    elseif port=="PortC"
        ActivateTriggerIn(TrigInExtDigOut,6)
    elseif port=="PortD"
        ActivateTriggerIn(TrigInExtDigOut,7)
    end

end

function getTtlIn(ttlInArray)

    UpdateWireOuts()
    ttlIn=GetWireOutValue(WireOutTtlIn)
    for i=1:16
        ttlInArray[i] = 0
        if (ttlIn & (1 << (i-1))) > 0
            ttlInArray[i] = 1
        end
    end
end

function setLedDisplay(ledArray)

    ledOut=0
    for i=1:8
        if ledArray[i]>0
            ledOut += 1 << (i-1)
        end
    end

    println(ledOut)

    SetWireInValue(WireInLedDisplay,ledOut)
    UpdateWireIns()

end

function runBoard()
    
    ActivateTriggerIn(TrigInSpiStart,0)
end

function isRunning()

    UpdateWireOuts()
    value=GetWireOutValue(WireOutSpiRunning)

    if ((value & 0x01) == 0)
        return false
    else
        return true
    end
         
end

function flushBoard()

    usbBuffer = Array(Uint8,USB_BUFFER_SIZE)
    usbBuffer = convert(SharedArray{Uint8,1},usbBuffer)
    
    while (numWordsInFifo() >= (USB_BUFFER_SIZE/2))
        ReadFromPipeOut(PipeOutData, USB_BUFFER_SIZE, usbBuffer)
    end
    
    while (numWordsInFifo() > 0)
        ReadFromPipeOut(PipeOutData, (2 * numWordsInFifo()), usbBuffer)
    end
end

function numWordsInFifo()

    UpdateWireOuts()

    #Rhythm makes this a Uint32 (not sure that it matters)
    return GetWireOutValue(WireOutNumWordsMsb)<<16+GetWireOutValue(WireOutNumWordsLsb)
    
end

function readDataBlocks(numBlocks::Int, time::Array{Int32,1}, s::DArray{Sorting, 1, Array{Sorting,1}},ss="METHOD_NOSORT")

    usbBuffer = Array(Uint8,USB_BUFFER_SIZE) #need to allocate this somewhere so it doesn't rehappen everytime (not sure if global variable is only option for this. Could make it an input?)
    usbBuffer=convert(SharedArray{Uint8,1},usbBuffer)

    #Lets stop recalculating this
    numWordsToRead = numBlocks * calculateDataBlockSizeInWords(numDataStreams::Int64)

    if (numWordsInFifo() < numWordsToRead)
        return false
    end

    numBytesToRead = 2 * numWordsToRead

    if (numBytesToRead > USB_BUFFER_SIZE)
        println("USB buffer size exceeded")
        return false
    end

    #this is where usbBuffer is filled from Fifo
    usbBuffer=ReadFromPipeOut(PipeOutData, convert(Clong, numBytesToRead), usbBuffer)

    for i=0:(numBlocks-1)
        
        # make data block from fillFromUsbBuffer
        # add block to queue       
        dataBlock=fillFromUsbBuffer(usbBuffer,i,numDataStreams::Int64,s)
        
        #Add time from dataBlock
        append!(time, dataBlock)

        if ss=="METHOD_SORT"

            #parallel
            map!(onlineSort,s)
                      
        elseif ss=="METHOD_NOSORT"
        
        elseif ss=="METHOD_SORTCAL"
            
            map!(onlineCal,s)

        end
        
    end

    return true
   
end


function calculateDataBlockSizeInWords(nDataStreams::Int64)

    numWords = SAMPLES_PER_DATA_BLOCK * (4+2+(nDataStreams*36)+8+2)
                           
    # return convert(Uint32, numWords)

    return numWords
    #4 = magic number; 2 = time stamp; 36 = (32 amp channels + 3 aux commands + 1 filler word); 8 = ADCs; 2 = TTL in/out

end

function fillFromUsbBuffer(usbBuffer::SharedArray{Uint8,1}, blockIndex::Int64, nDataStreams::Int64, s::DArray{Sorting, 1, Array{Sorting,1}})

    #Need to add extra input so only read and return what is needed
    
    #Remember that Julia starts with index=1 and not zero
    #This is really a constant after the experiment starts. probably shouldn't recalculate this everytime
    #every word is two bytes
    numBytesPerBlock=convert(Int,2 * calculateDataBlockSizeInWords(nDataStreams) / SAMPLES_PER_DATA_BLOCK)
    index = blockIndex * numBytesPerBlock * SAMPLES_PER_DATA_BLOCK + 1

    timeStamp=Array(Int32,SAMPLES_PER_DATA_BLOCK)

    index+=8
    for t=1:SAMPLES_PER_DATA_BLOCK
        timeStamp[t]=convert(Int32,convertUsbTimeStamp(usbBuffer,index))
        index+=numBytesPerBlock
    end

    # 8 + 4 + 3*nDataStreams * 2 arrives at first amp channel (subtract 2 based on the way it is indexed)
    start=10+6*nDataStreams
    
    @sync @parallel for i=1:nDataStreams*32
        ind=1
        for j=start+i+i:numBytesPerBlock:numBytesPerBlock*SAMPLES_PER_DATA_BLOCK
            s[i].rawSignal[ind]=convertUsbWord(usbBuffer,j)
            ind+=1
        end
    end
        
    return timeStamp
    
end

function queueToFile(time::Array{Int32,1}, s::DArray{Sorting, 1, Array{Sorting,1}}, saveOut)

    #don't need initial zeros anymore since its preallocated
    #need to fill only new data in preallocated array
    
    time=time[3:end] #get rid of initial zeros

    h5open(saveOut,"r+") do fid
        d=d_open(fid, "time")
        set_dims!(d,(length(d)+length(time),))
        d[(length(d[:])-length(time)+1):end]=time
        
        @sync @parallel for i=1:length(s)
            #if sorting was  used, length of each electrode array is not necessarily the same
            e=d_open(fid, string(i))
            set_dims!(e,(length(e)+s[i].numSpikes,))
            e[(length(e[:])-s[i].numSpikes+1):end]=s[i].electrode[1:s[i].numSpikes]
            e=d_open(fid, string("n",i))
            set_dims!(e,(length(e)+s[i].numSpikes,))
            e[(length(e[:])-s[i].numSpikes+1):end]=s[i].neuronnum[1:s[i].numSpikes]
        end
        
    end

    time=zeros(Int32,2)
    @sync @parallel for i=1:length(s)
        s[i].electrode=zeros(Int,length(s[i].electrode))
        s[i].neuronnum=zeros(Int,length(s[i].neuronnum))
        s[i].numSpikes=2
    end
    
    
end

function convertUsbTimeStamp(usbBuffer::SharedArray{Uint8,1}, index::Int64)

    x1 = convert(Uint32,usbBuffer[index])
    x2 = convert(Uint32,usbBuffer[index+1])
    x3 = convert(Uint32,usbBuffer[index+2])
    x4 = convert(Uint32,usbBuffer[index+3])

    return ((x4<<24) + (x3<<16) + (x2<<8) + (x1<<0))
end

function convertUsbWord(usbBuffer::SharedArray{Uint8,1}, index::Int64)

    x1=convert(Uint32, usbBuffer[index])
    x2=convert(Uint32, usbBuffer[index+1])

    #The original C++ Rhythm API uses Int32, but Julia hasn't been playing nice with making sure that Int32s are type stable through calculations.
    return convert(Int64, ((x2<<8) | (x1<<0)))
    
end

#Library Wrapper Functions


function SetWireInValue(ep, val, mask = 0xffffffff)
    
    er=ccall((:okFrontPanel_SetWireInValue,mylib),Cint,(Ptr{Void},Int,Culong,Culong),y,ep, val, mask)

    return er
end

function UpdateWireIns()

    ccall((:okFrontPanel_UpdateWireIns,mylib),Void,(Ptr{Void},),y)

end

function UpdateWireOuts()

    ccall((:okFrontPanel_UpdateWireOuts,mylib),Void,(Ptr{Void},),y)

end


function ActivateTriggerIn(epAddr::Uint8,bit::Int)
    
    er=ccall((:okFrontPanel_ActivateTriggerIn,mylib),Cint,(Ptr{Void},Int32,Int32),y,epAddr,bit)

    return er

end

function GetWireOutValue(epAddr::Uint8)

    value = ccall((:okFrontPanel_GetWireOutValue,mylib),Culong,(Ptr{Void},Int32),y,epAddr)

    return value

end

function ReadFromPipeOut(epAddr::Uint8, length, data::SharedArray{Uint8,1})

   #CCall can fill Shared Arrays!
   ccall((:okFrontPanel_ReadFromPipeOut,mylib),Clong,(Ptr{Void},Int32,Clong,Ptr{Uint8}),y,epAddr,length,data)

    return data
   
end

end
