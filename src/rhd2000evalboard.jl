
module rhd2000evalboard

using HDF5, SortSpikes, DistributedArrays, ExtractSpikes

export RHD2000, setMaxTimeStep, setContinuousRunMode, runBoard, isRunning, numWordsInFifo,flushBoard, enableDataStream, readDataBlocks, queueToFile, setDataSource, selectAuxCommandLength, selectAuxCommandBank, uploadCommandList, fillFromUsbBuffer

#Constant parameters

type RHD2000
    lib::ASCIIString
    bit::ASCIIString
    sampleRate::Int64
    numDataStreams::Int64
    dataStreamEnabled::Array{Int64,2}
    usbBuffer::Array{Uint8,1}
    numWords::Int64
    numBytesPerBlock
end

function RHD2000(lib::ASCIIString,bit::ASCIIString)
    mylib="/home/nicolelislab/Intan.jl/libokFrontPanel.so"
    myfile="/home/nicolelislab/Intan.jl/main.bit"

    sampleRate=30000
    numDataStreams=0

    dataStreamEnabled=zeros(Int64,1,MAX_NUM_DATA_STREAMS)

    usbBuffer = Array(Uint8,USB_BUFFER_SIZE)
    usbBuffer = convert(SharedArray{Uint8,1},usbBuffer)

    numWords = 0

    numBytesPerBlock = 0
    
    RHD2000(lib,bit,sampleRate,numDataStreams,dataStreamEnabled,usbBuffer,numWords,numBytesPerBlock)
end

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

const y = ccall((:okFrontPanel_Construct, mylib), Ptr{Void}, ())

function init_board(lib::ASCIIString,bit::ASCIIString,)

    rhd=RHD2000(lib,bit);
    
    #Opal Kelly XEM6010 board
    open_board(rhd)

    # Load Rhythm FPGA configuration bitfile (provided by Intan Technologies).
    uploadFpgaBitfile(rhd);

    #Initialize board
    initialize_board(rhd)

    #For 64 channel need two data streams, and data will come in 
    #on the rising AND falling edges of SCLK
    enableDataStream(rhd,1, true)
    setDataSource(rhd,0, 0) #port A MISO1
    setDataSource(rhd,1, 8) #port A MISO1 DDR

    #Select per-channel amplifier sampling rate
    setSampleRate(rhd,20000)

    #Now that we have set our sampling rate, we can set the MISO sampling delay
    #which is dependent on the sample rate. We use a 6.0 foot cable
    setCableLengthFeet(rhd,"PortA", 6.0)

    # Let's turn one LED on to indicate that the program is running.
    ledArray=[1,1,0,0,0,0,0,0]
    setLedDisplay(rhd,ledArray)

    nothing
    
end

function open_board(rhd::RHD2000)

    println("Scanning USB for Opal Kelly devices...")
    nDevices=ccall((:okFrontPanel_GetDeviceCount,rhd.lib), Int, (Ptr{Void},), y) 
    println("Found ", nDevices, " Opal Kelly device(s)")

    #Get Serial Number (I'm assuing there is only one device)
    serial=Array(Uint8,11)
    ccall((:okFrontPanel_GetDeviceListSerial,rhd.lib), Int32, (Ptr{Void}, Int, Ptr{Uint8}), y, 0,serial)
    serial[end]=0
    serialnumber=bytestring(pointer(serial))
    println("Serial number of device 0 is ", serialnumber)
    
    #Open by serial 
    if (ccall((:okFrontPanel_OpenBySerial, rhd.lib), Cint, (Ptr{Void},Ptr{Uint8}),y,serialnumber)!=0)
        println("Device could not be opened. Is one connected?")
        return -2
    end
    
    #configure on-board PLL
    ccall((:okFrontPanel_LoadDefaultPLLConfiguration,rhd.lib), Cint, (Ptr{Void},),y)

    return 1

end

function uploadFpgaBitfile(rhd::RHD2000)

    #upload configuration file
    errorcode=ccall((:okFrontPanel_ConfigureFPGA,rhd.lib),Cint,(Ptr{Void},Ptr{Uint8}),y,rhd.file)

    #error checking goes here
    if errorcode==0
        println("FPGA configuration loaded.")
    else
        println("FPGA configuration failed.")
    end
    
    
    #Check if FrontPanel Support is enabled
    ccall((:okFrontPanel_IsFrontPanelEnabled,rhd.lib),Bool,(Ptr{Void},),y)

    UpdateWireOuts(rhd)
    
    boardId = GetWireOutValue(rhd,WireOutBoardId)
    boardVersion = GetWireOutValue(rhd,WireOutBoardVersion)
    if (boardId != RHYTHM_BOARD_ID)
        println("FPGA configuration does not support Rythm. Incorrect board ID: ", boardId)
    else
        println("Rhythm configuration file successfully loaded. Rhythm version number: ", boardVersion)
    end
    
end

function initialize_board(rhd::RHD2000)
  
    resetBoard(rhd)
    setSampleRate(rhd,30000)
    selectAuxCommandBank(rhd,"PortA", "AuxCmd1", 0)
    selectAuxCommandBank(rhd,"PortB", "AuxCmd1", 0)
    selectAuxCommandBank(rhd,"PortC", "AuxCmd1", 0)
    selectAuxCommandBank(rhd,"PortD", "AuxCmd1", 0)
    selectAuxCommandBank(rhd,"PortA", "AuxCmd2", 0)
    selectAuxCommandBank(rhd,"PortB", "AuxCmd2", 0)
    selectAuxCommandBank(rhd,"PortC", "AuxCmd2", 0)
    selectAuxCommandBank(rhd,"PortD", "AuxCmd2", 0)
    selectAuxCommandBank(rhd,"PortA", "AuxCmd3", 0)
    selectAuxCommandBank(rhd,"PortB", "AuxCmd3", 0)
    selectAuxCommandBank(rhd,"PortC", "AuxCmd3", 0)
    selectAuxCommandBank(rhd,"PortD", "AuxCmd3", 0)
    selectAuxCommandLength(rhd,"AuxCmd1", 0, 0)
    selectAuxCommandLength(rhd,"AuxCmd2", 0, 0)
    selectAuxCommandLength(rhd,"AuxCmd3", 0, 0)

    setContinuousRunMode(rhd,true)
    
    setMaxTimeStep(rhd,4294967295) #4294967395 == (2^32 - 1)

    setCableLengthFeet(rhd,"PortA", 3.0)  # assume 3 ft cables
    setCableLengthFeet(rhd,"PortB", 3.0)
    setCableLengthFeet(rhd,"PortC", 3.0)
    setCableLengthFeet(rhd,"PortD", 3.0)

    setDspSettle(rhd,false)

    setDataSource(rhd,0, PortA1)
    setDataSource(rhd,1, PortB1)
    setDataSource(rhd,2, PortC1)
    setDataSource(rhd,3, PortD1)
    setDataSource(rhd,4, PortA2)
    setDataSource(rhd,5, PortB2)
    setDataSource(rhd,6, PortC2)
    setDataSource(rhd,7, PortD2)

    #remember that julia indexes with 1's instead of 0's to start an array
    enableDataStream(rhd,0, true)
    for i=1:(MAX_NUM_DATA_STREAMS-1)
        enableDataStream(rhd,i,false)
    end

    clearTtlOut(rhd)

    enableDac(rhd,0, false)
    enableDac(rhd,1, false)
    enableDac(rhd,2, false)
    enableDac(rhd,3, false)
    enableDac(rhd,4, false)
    enableDac(rhd,5, false)
    enableDac(rhd,6, false)
    enableDac(rhd,7, false)
    selectDacDataStream(rhd,0, 0)
    selectDacDataStream(rhd,1, 0)
    selectDacDataStream(rhd,2, 0)
    selectDacDataStream(rhd,3, 0)
    selectDacDataStream(rhd,4, 0)
    selectDacDataStream(rhd,5, 0)
    selectDacDataStream(rhd,6, 0)
    selectDacDataStream(rhd,7, 0)
    selectDacDataChannel(rhd,0, 0)
    selectDacDataChannel(rhd,1, 0)
    selectDacDataChannel(rhd,2, 0)
    selectDacDataChannel(rhd,3, 0)
    selectDacDataChannel(rhd,4, 0)
    selectDacDataChannel(rhd,5, 0)
    selectDacDataChannel(rhd,6, 0)
    selectDacDataChannel(rhd,7, 0)

    setDacManual(rhd,32768)    # midrange value = 0 V

    setDacGain(rhd,0)
    setAudioNoiseSuppress(rhd,0)

    setTtlMode(rhd,1)   # Digital outputs 0-7 are DAC comparators; 8-15 under manual control

    setDacThreshold(rhd,0, 32768, true)
    setDacThreshold(rhd,1, 32768, true)
    setDacThreshold(rhd,2, 32768, true)
    setDacThreshold(rhd,3, 32768, true)
    setDacThreshold(rhd,4, 32768, true)
    setDacThreshold(rhd,5, 32768, true)
    setDacThreshold(rhd,6, 32768, true)
    setDacThreshold(rhd,7, 32768, true)

    enableExternalFastSettle(rhd,false)
    setExternalFastSettleChannel(rhd,0)

    enableExternalDigOut(rhd,"PortA", false)
    enableExternalDigOut(rhd,"PortB", false)
    enableExternalDigOut(rhd,"PortC", false)
    enableExternalDigOut(rhd,"PortD", false)
    setExternalDigOutChannel(rhd,"PortA", 0)
    setExternalDigOutChannel(rhd,"PortB", 0)
    setExternalDigOutChannel(rhd,"PortC", 0)
    setExternalDigOutChannel(rhd,"PortD", 0)
       
end

function resetBoard()

    SetWireInValue(rhd,WireInResetRun, 0x01, 0x01)
    UpdateWireIns(rhd)
    SetWireInValue(rhd,WireInResetRun, 0x00, 0x01)
    UpdateWireIns(rhd)
    
end

function setSampleRate(rhd::RHD2000,newSampleRate::Int64)

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
  
    rhd.sampleRate=newSampleRate

    #Wait for DcmProgDone==1 before reprogramming clock synthesizer
    while (isDcmProgDone(rhd)==false)   
    end
   
    #Reprogram clock synthesizer

    SetWireInValue(rhd,WireInDataFreqPll,(256 * convert(Culong,M) + convert(Culong,D)))
    UpdateWireIns(rhd)  
    ActivateTriggerIn(rhd,TrigInDcmProg,0)
   
    #Wait for DataClkLocked = 1 before allowing data acquisition to continue
    while (isDataClockLocked(rhd) == false)
    end
                 
end

function isDcmProgDone(rhd::RHD2000)

    UpdateWireOuts(rhd)
    value=GetWireOutValue(rhd,WireOutDataClkLocked)

    return ((value & 0x0002) > 1)

end

function isDataClockLocked(rhd::RHD2000)

    UpdateWireOuts(rhd)
    value=GetWireOutValue(rhd,WireOutDataClkLocked)
    
    return ((value & 0x0001) > 0)

end

function uploadCommandList(rhd::RHD2000,commandList, auxCommandSlot, bank)

    #error checking goes here

    for i=1:length(commandList)

        SetWireInValue(rhd,WireInCmdRamData, commandList[i])
        SetWireInValue(rhd,WireInCmdRamAddr, i-1)
        SetWireInValue(rhd,WireInCmdRamBank, bank)
        UpdateWireIns(rhd)
        if auxCommandSlot == "AuxCmd1"
            ActivateTriggerIn(rhd,TrigInRamWrite,0)
        elseif auxCommandSlot == "AuxCmd2"
            ActivateTriggerIn(rhd,TrigInRamWrite,1)
        elseif auxCommandSlot == "AuxCmd3"
            ActivateTriggerIn(rhd,TrigInRamWrite,2)
        end
        
    end
    
end

function selectAuxCommandBank(rhd::RHD2000,port, commandslot, bank)

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
        SetWireInValue(rhd,WireInAuxCmdBank1,(bank<<bitShift),(0x000f<<bitShift))
    elseif commandslot=="AuxCmd2"
        SetWireInValue(rhd,WireInAuxCmdBank2,(bank<<bitShift),(0x000f<<bitShift))
    elseif commandslot=="AuxCmd3"
        SetWireInValue(rhd,WireInAuxCmdBank3,(bank<<bitShift),(0x000f<<bitShift))
    end

    UpdateWireIns(rhd)

end

function selectAuxCommandLength(rhd::RHD2000,commandslot,loopIndex,endIndex)
    
    #Error checking goes here

    if commandslot=="AuxCmd1"
        SetWireInValue(rhd,WireInAuxCmdLoop1,loopIndex)
        SetWireInValue(rhd,WireInAuxCmdLength1,endIndex)
    elseif commandslot=="AuxCmd2"
        SetWireInValue(rhd,WireInAuxCmdLoop2,loopIndex)
        SetWireInValue(rhd,WireInAuxCmdLength2,endIndex)
    elseif commandslot=="AuxCmd3"
        SetWireInValue(rhd,WireInAuxCmdLoop3,loopIndex)
        SetWireInValue(rhd,WireInAuxCmdLength3,endIndex)
    end

    UpdateWireIns(rhd)
    
end

function setContinuousRunMode(rhd::RHD2000,continuousMode)
    
    if continuousMode
        SetWireInValue(rhd,WireInResetRun,0x02,0x02)
    else
        SetWireInValue(rhd,WireInResetRun,0x00,0x02)
    end

    UpdateWireIns(rhd)

end

function setMaxTimeStep(rhd::RHD2000,maxTimeStep)

    maxTimeStep=convert(Uint32, maxTimeStep)
    
    maxTimeStepLsb = maxTimeStep & 0x0000ffff
    maxTimeStepMsb = maxTimeStep & 0xffff0000

    SetWireInValue(rhd,WireInMaxTimeStepLsb,maxTimeStepLsb)
    SetWireInValue(rhd,WireInMaxTimeStepMsb,(maxTimeStepMsb >> 16))
    UpdateWireIns(rhd)
    
end

function setCableLengthFeet(rhd::RHD2000,port, lengthInFeet::Float64)
    setCableLengthMeters(rhd,port, .3048 * lengthInFeet)
end

function setCableLengthMeters(rhd::RHD2000,port, lengthInMeters::Float64)

    speedOfLight = 299792458.0
    xilinxLvdsOutputDelay=1.9e-9
    xilinxLvdsInputDelay=1.4e-9
    rhd2000Delay=9.0e-9
    misoSettleTime=6.7e-9

    tStep=1.0 / (2800.0 * rhd.sampleRate)

    cableVelocity=.555 * speedOfLight

    distance = 2.0 * lengthInMeters

    timeDelay = (distance / cableVelocity) + xilinxLvdsOutputDelay + rhd2000Delay + xilinxLvdsInputDelay + misoSettleTime

    delay = convert(Int32,floor(((timeDelay / tStep) + 1.0) +0.5))

    if delay < 1
        delay=1
    end

    setCableDelay(rhd,port, delay)
end

function setCableDelay(rhd::RHD2000,port, delay)
    
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
    
    SetWireInValue(rhd,WireInMisoDelay, delay << bitShift, 0x000f << bitShift)
    UpdateWireIns(rhd)
    
end

function setDspSettle(rhd::RHD2000,enabled)

    SetWireInValue(rhd,WireInResetRun, (enabled ? 0x04 : 0x00), 0x04)
    UpdateWireIns(rhd)

end

function setDataSource(rhd::RHD2000,stream, dataSource)

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
    SetWireInValue(rhd,endPoint,(dataSource << bitShift), (0x000f << bitShift))
    UpdateWireIns(rhd)

end

function enableDataStream(rhd::RHD2000,stream::Int, enabled::Bool)
    
    #error checking goes here

    stream=convert(Int32,stream)
    if enabled
        if rhd.dataStreamEnabled[stream+1] == 0
            SetWireInValue(rhd,WireInDataStreamEn,0x0001 << stream, 0x0001 << stream)
            UpdateWireIns(rhd)
            rhd.dataStreamEnabled[stream+1] = 1;
            rhd.numDataStreams=rhd/numDataStreams+1;
        end
    else
        if rhd.dataStreamEnabled[stream+1] == 1
            SetWireInValue(rhd,WireInDataStreamEn,0x0000 << stream, 0x0001 << stream)
            UpdateWireIns(rhd)
            rhd.dataStreamEnabled[stream+1] = 0;
            rhd.numDataStream=rhd.numDataStreams-1;
        end
    end
                
end

function enableDac(rhd::RHD2000,dacChannel::Int, enabled::Bool)

    #error checking goes here

    if dacChannel == 0
        SetWireInValue(rhd,WireInDacSource1,(enabled ? 0x0200 : 0x0000), 0x0200)
    elseif dacChannel == 1
        SetWireInValue(rhd,WireInDacSource2,(enabled ? 0x0200 : 0x0000), 0x0200)
    elseif dacChannel == 2
        SetWireInValue(rhd,WireInDacSource3,(enabled ? 0x0200 : 0x0000), 0x0200)
    elseif dacChannel == 3
        SetWireInValue(rhd,WireInDacSource4,(enabled ? 0x0200 : 0x0000), 0x0200)
    elseif dacChannel == 4
        SetWireInValue(rhd,WireInDacSource5,(enabled ? 0x0200 : 0x0000), 0x0200)
    elseif dacChannel == 5
        SetWireInValue(rhd,WireInDacSource6,(enabled ? 0x0200 : 0x0000), 0x0200)
    elseif dacChannel == 6
        SetWireInValue(rhd,WireInDacSource7,(enabled ? 0x0200 : 0x0000), 0x0200)
    elseif dacChannel == 7
        SetWireInValue(rhd,WireInDacSource8,(enabled ? 0x0200 : 0x0000), 0x0200)
    end

    UpdateWireIns(rhd)

end

function selectDacDataStream(rhd::RHD2000,dacChannel, stream)
    #error checking goes here

    
    if dacChannel == 0
         SetWireInValue(rhd,WireInDacSource1, stream << 5, 0x01e0)
    elseif dacChannel == 1
         SetWireInValue(rhd,WireInDacSource2, stream << 5, 0x01e0)
    elseif dacChannel == 2
         SetWireInValue(rhd,WireInDacSource3, stream << 5, 0x01e0)
    elseif dacChannel == 3
         SetWireInValue(rhd,WireInDacSource4, stream << 5, 0x01e0)
    elseif dacChannel == 4
         SetWireInValue(rhd,WireInDacSource5, stream << 5, 0x01e0)
    elseif dacChannel == 5
         SetWireInValue(rhd,WireInDacSource6, stream << 5, 0x01e0)
    elseif dacChannel == 6
         SetWireInValue(rhd,WireInDacSource7, stream << 5, 0x01e0)
    elseif dacChannel == 7
         SetWireInValue(rhd,WireInDacSource8, stream << 5, 0x01e0)
    end

    UpdateWireIns(rhd)
        
end

function selectDacDataChannel(rhd::RHD2000,dacChannel::Int, dataChannel)
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
    
end

function setDacManual(rhd::RHD2000,value)
    #error checking goes here

    SetWireInValue(rhd,WireInDacManual,value)
    UpdateWireIns(rhd)
    
end

function setDacGain(rhd::RHD2000,gain)
    #error checking goes here

    
    SetWireInValue(rhd,WireInResetRun,gain << 13, 0xe000)
    UpdateWireIns(rhd)
    
end

function setAudioNoiseSuppress(rhd::RHD2000,noiseSuppress)
    #error checking goes here

    SetWireInValue(rhd,WireInResetRun, noiseSuppress << 6, 0x1fc0)
    UpdateWireIns(rhd)

end

function setTtlMode(rhd::RHD2000,mode)
    #error checking goes here

    SetWireInValue(rhd,WireInResetRun, mode << 3, 0x0008)
    UpdateWireIns(rhd)

    nothing

end

function clearTtlOut(rhd::RHD2000)

    SetWireInValue(rhd,WireInTtlOut, 0x0000)
    UpdateWireIns(rhd)

    nothing
    
end


function setDacThreshold(rhd::RHD2000,dacChannel, threshold, trigPolarity)

    #error checking goes here

    #Set threshold level
    SetWireInValue(rhd,WireInMultiUse,threshold)
    UpdateWireIns(rhd)
    ActivateTriggerIn(rhd,TrigInDacThresh, dacChannel)

    #Set threshold polarity
    SetWireInValue(rhd,WireInMultiUse, (trigPolarity ? 1 : 0))
    UpdateWireIns(rhd)
    ActivateTriggerIn(rhd,TrigInDacThresh, dacChannel+8)

    nothing
    
end

function enableExternalFastSettle(rhd::RHD2000,enable)

    SetWireInValue(rhd,WireInMultiUse, (enable ? 1 : 0))
    UpdateWireIns(rhd)
    ActivateTriggerIn(rhd,TrigInExtFastSettle,0)

    nothing
    
end

function setExternalFastSettleChannel(rhd::RHD2000,channel)

    #error checking goes here

    SetWireInValue(rhd,WireInMultiUse,channel)
    UpdateWireIns(rhd)
    ActivateTriggerIn(rhd,TrigInExtFastSettle,1)

    nothing
    
end

function enableExternalDigOut(rhd::RHD2000,port, enable)

    SetWireInValue(rhd,WireInMultiUse, (enable ? 1 : 0))
    UpdateWireIns(rhd)

    if port=="PortA"
        ActivateTriggerIn(rhd,TrigInExtDigOut,0)
    elseif port=="PortB"
        ActivateTriggerIn(rhd,TrigInExtDigOut,1)
    elseif port=="PortC"
        ActivateTriggerIn(rhd,TrigInExtDigOut,2)
    elseif port=="PortD"
        ActivateTriggerIn(rhd,TrigInExtDigOut,3)
    end

    nothing
    
end

function setExternalDigOutChannel(rhd::RHD2000,port, channel)

    SetWireInValue(rhd,WireInMultiUse,channel)
    UpdateWireIns(rhd)

    if port=="PortA"
        ActivateTriggerIn(rhd,TrigInExtDigOut,4)
    elseif port=="PortB"
        ActivateTriggerIn(rhd,TrigInExtDigOut,5)
    elseif port=="PortC"
        ActivateTriggerIn(rhd,TrigInExtDigOut,6)
    elseif port=="PortD"
        ActivateTriggerIn(rhd,TrigInExtDigOut,7)
    end

end

function getTtlIn(rhd::RHD2000,ttlInArray)

    UpdateWireOuts(rhd)
    ttlIn=GetWireOutValue(rhd,WireOutTtlIn)
    for i=1:16
        ttlInArray[i] = 0
        if (ttlIn & (1 << (i-1))) > 0
            ttlInArray[i] = 1
        end
    end

    ttlInArray
end

function setLedDisplay(rhd::RHD2000,ledArray)

    ledOut=0
    for i=1:8
        if ledArray[i]>0
            ledOut += 1 << (i-1)
        end
    end

    println(ledOut)

    SetWireInValue(rhd,WireInLedDisplay,ledOut)
    UpdateWireIns(rhd)

    nothing
    
end

function runBoard(rhd::RHD2000)
    
    ActivateTriggerIn(rhd,TrigInSpiStart,0)

    nothing
    
end

function isRunning(rhd::RHD2000)

    UpdateWireOuts(rhd)
    value=GetWireOutValue(rhd,WireOutSpiRunning)

    if ((value & 0x01) == 0)
        return false
    else
        return true
    end
         
end

function flushBoard(rhd::RHD2000)

    while (numWordsInFifo(rhd) >= (USB_BUFFER_SIZE/2))
        ReadFromPipeOut(rhd,PipeOutData, USB_BUFFER_SIZE, rhd.usbBuffer)
    end
    
    while (numWordsInFifo(rhd) > 0)
        ReadFromPipeOut(rhd,PipeOutData, (2 * numWordsInFifo(rhd)), rhd.usbBuffer)
    end

    nothing
end

function numWordsInFifo(rhd::RHD2000)

    UpdateWireOuts(rhd)

    #Rhythm makes this a Uint32 (not sure that it matters)
    return GetWireOutValue(rhd,WireOutNumWordsMsb)<<16+GetWireOutValue(WireOutNumWordsLsb)
    
end

function readDataBlocks(rhd::RHD2000,numBlocks::Int64, time::Array{Int32,1}, s::DArray{Sorting, 1, Array{Sorting,1}}, ss="METHOD_NOSORT")

    if (numWordsInFifo(rhd) < rhd.numWords)
        return false
    end

    numBytesToRead = 2 * rhd.numWords

    if (numBytesToRead > USB_BUFFER_SIZE)
        println("USB buffer size exceeded")
        return false
    end

    #this is where usbBuffer is filled from Fifo
    ReadFromPipeOut(rhd,PipeOutData, convert(Clong, numBytesToRead), rhd.usbBuffer)

    for i=0:(numBlocks-1)
        
        # make data block from fillFromUsbBuffer
        # add block to queue       
        dataBlock=fillFromUsbBuffer(rhd,i,s)
        
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


function calculateDataBlockSizeInWords(rhd::RHD2000)

    rhd.numWords = SAMPLES_PER_DATA_BLOCK * (4+2+(rhd.nDataStreams*36)+8+2)
                           
    # return convert(Uint32, numWords)

    nothing
    #4 = magic number; 2 = time stamp; 36 = (32 amp channels + 3 aux commands + 1 filler word); 8 = ADCs; 2 = TTL in/out

end

function calculateDataBlockSizeinBytes(rhd::RHD2000)

    rhd.numBytesPerBlock=convert(Int64,2 * rhd.numWords / SAMPLES_PER_DATA_BLOCK)

    nothing
    
end


function fillFromUsbBuffer(rhd::RHD2000, blockIndex::Int64, s::DArray{Sorting, 1, Array{Sorting,1}})
    
    index = blockIndex * rhd.numBytesPerBlock * SAMPLES_PER_DATA_BLOCK + 1

    timeStamp=Array(Int32,SAMPLES_PER_DATA_BLOCK)
    
    index+=8
    for t=1:SAMPLES_PER_DATA_BLOCK
        timeStamp[t]=convert(Int32,convertUsbTimeStamp(rhd.usbBuffer,index))
        index+=rhd.numBytesPerBlock
    end

    # 8 + 4 + 3*nDataStreams * 2 arrives at first amp channel (subtract 2 based on the way it is indexed)
    start=10+6*rhd.numDataStreams
    
    @parallel for i=1:rhd.numDataStreams*32
        ind=start+i+i
        b=0
        for j=1:SAMPLES_PER_DATA_BLOCK
            #s[i].rawSignal[ind]=convertUsbWord(usbBuffer,j)
            b=(convert(Uint32,rhd.usbBuffer[ind+1]) << 8) | (convert(Uint32,rhd.usbBuffer[ind]) << 0)
            s[i].rawSignal[j]=convert(Int64,b)
            ind+=rhd.numBytesPerBlock
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
        s[i].electrode[:]=zeros(Int,length(s[i].electrode))
        s[i].neuronnum[:]=zeros(Int,length(s[i].neuronnum))
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


function SetWireInValue(rhd::RHD2000, ep, val, mask = 0xffffffff)
    
    er=ccall((:okFrontPanel_SetWireInValue,rhd.lib),Cint,(Ptr{Void},Int,Culong,Culong),y,ep, val, mask)

    return er
end

function UpdateWireIns(rhd::RHD2000)

    ccall((:okFrontPanel_UpdateWireIns,rhd.lib),Void,(Ptr{Void},),y)

    nothing

end

function UpdateWireOuts(rhd::RHD2000)

    ccall((:okFrontPanel_UpdateWireOuts,rhd.lib),Void,(Ptr{Void},),y)

    nothing

end


function ActivateTriggerIn(rhd::RHD2000,epAddr::Uint8,bit::Int)
    
    er=ccall((:okFrontPanel_ActivateTriggerIn,rhd.lib),Cint,(Ptr{Void},Int32,Int32),y,epAddr,bit)

    return er

end

function GetWireOutValue(rhd::RHD2000,epAddr::Uint8)

    value = ccall((:okFrontPanel_GetWireOutValue,rhd.lib),Culong,(Ptr{Void},Int32),y,epAddr)

    return value

end

function ReadFromPipeOut(epAddr::Uint8, length, data::SharedArray{Uint8,1})

    #CCall can fill Shared Arrays!
    ccall((:okFrontPanel_ReadFromPipeOut,rhd.lib),Clong,(Ptr{Void},Int32,Clong,Ptr{Uint8}),y,epAddr,length,data)

    return data
   
end

end
