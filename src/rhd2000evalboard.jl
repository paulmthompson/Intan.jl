

abstract Amp

type RHD2164 <: Amp
    port::Array{Int64,1}
end

function RHD2164(port::ASCIIString)
    if port=="PortA1"
        ports=[PortA1,PortA1Ddr]
    elseif port=="PortA2"
        ports=[PortA2,PortA2Ddr]
    elseif port=="PortB1"
        ports=[PortB1,PortB1Ddr]
    elseif port=="PortB2"
        ports=[PortB2,PortB2Ddr]
    elseif port=="PortC1"
        ports=[PortC1,PortC1Ddr]
    elseif port=="PortC2"
        ports=[PortC2,PortC2Ddr]
    elseif port=="PortD1"
        ports=[PortD1,PortD1Ddr]
    elseif port=="PortD2"
        ports=[PortD2,PortD2Ddr]
    else
        ports=[0,0]
    end

    RHD2164(ports)
    
end

type RHD2132 <: Amp
    port::Array{Int64,1}
end

function RHD2132(port::ASCIIString)
    if port=="PortA1"
        ports=[PortA1]
    elseif port=="PortA2"
        ports=[PortA2]
    elseif port=="PortB1"
        ports=[PortB1]
    elseif port=="PortB2"
        ports=[PortB2]
    elseif port=="PortC1"
        ports=[PortC1]
    elseif port=="PortC2"
        ports=[PortC2]
    elseif port=="PortD1"
        ports=[PortD1]
    elseif port=="PortD2"
        ports=[PortD2]
    else
        ports=[0]
    end

    RHD2132(ports)
end


type RHD2000{T<:Amp,U,V<:AbstractArray{Int64,2},W<:AbstractArray{Spike,2},X<:AbstractArray{Int64,1}}
    board::Ptr{Void}
    sampleRate::Int64
    numDataStreams::Int64
    dataStreamEnabled::Array{Int64,2}
    usbBuffer::Array{UInt8,1}
    numWords::Int64
    numBytesPerBlock::Int64
    amps::Array{T,1}
    v::V
    s::U
    time::Array{Int32,1}
    buf::W
    nums::X
    cal::Int64
end

default_sort=Algorithm[DetectPower(),ClusterOSort(),AlignMax(),FeatureDD(),ReductionNone()]

function RHD2000{T<:Amp}(amps::Array{T,1},sort::ASCIIString,params=default_sort)

    numchannels=0

    for i=1:length(amps)
        if typeof(amps[i])==RHD2164
            numchannels+=64
        elseif typeof(amps[i])==2132
            numchannels+=32
        end
    end

    sampleRate=30000 #default
    numDataStreams=0

    dataStreamEnabled=zeros(Int64,1,MAX_NUM_DATA_STREAMS)

    usbBuffer = zeros(UInt8,USB_BUFFER_SIZE)

    numWords = 0

    numBytesPerBlock = 0

    mytime=zeros(Int32,10000)

    board = ccall((:okFrontPanel_Construct, lib), Ptr{Void}, ())

    if sort=="single"
        v=zeros(Int64,SAMPLES_PER_DATA_BLOCK,numchannels)
        s=create_multi(params...,numchannels,false)
        (buf,nums)=output_buffer(numchannels)
        RHD2000(board,sampleRate,numDataStreams,dataStreamEnabled,usbBuffer,numWords,numBytesPerBlock,amps,v,s,mytime,buf,nums,0)
    elseif sort=="parallel"
        v=convert(SharedArray{Int64,2},zeros(Int64,SAMPLES_PER_DATA_BLOCK,numchannels))
        s=create_multi(params...,numchannels,true)
        (buf,nums)=output_buffer(numchannels,true)
        RHD2000(board,sampleRate,numDataStreams,dataStreamEnabled,usbBuffer,numWords,numBytesPerBlock,amps,v,s,mytime,buf,nums,0)
    else
        v=zeros(Int64,SAMPLES_PER_DATA_BLOCK,numchannels)
        s=create_multi(params...,numchannels,false)
        (buf,nums)=output_buffer(numchannels)
        RHD2000(board,sampleRate,numDataStreams,dataStreamEnabled,usbBuffer,numWords,numBytesPerBlock,amps,v,s,mytime,buf,nums,0)
    end

end

function init_board!(rhd::RHD2000)
    
    #Opal Kelly XEM6010 board
    open_board(rhd)

    # Load Rhythm FPGA configuration bitfile (provided by Intan Technologies).
    uploadFpgaBitfile(rhd);

    #Initialize board
    initialize_board(rhd)

    #For 64 channel need two data streams, and data will come in 
    #on the rising AND falling edges of SCLK

    stream=0
    for i=1:length(rhd.amps)

        for j in rhd.amps.ports
            enableDataStream(rhd,stream,true)
            setDataSource(rhd,stream,j)
            stream+=1
        end
        
    end

    #Calculate Data Stream block size
    calculateDataBlockSizeInWords(rhd)
    calculateDataBlockSizeInBytes(rhd)
    
    #Select per-channel amplifier sampling rate
    setSampleRate(rhd,sr)

    #Now that we have set our sampling rate, we can set the MISO sampling delay
    #which is dependent on the sample rate. We use a 6.0 foot cable
    setCableLengthFeet(rhd,"PortA", 6.0)

    # Let's turn one LED on to indicate that the program is running.
    ledArray=[1,0,0,0,0,0,0,0]
    setLedDisplay(rhd,ledArray)

    #Set up an RHD2000 register object using this sample rate to optimize MUX-related register settings.
    r=CreateRHD2000Registers(Float64(sr))

    #Upload version with no ADC calibration to AuxCmd3 RAM Bank 0.
    commandList=createCommandListRegisterConfig(zeros(Int32,1),false,r)
    uploadCommandList(commandList, "AuxCmd3", 0)

    #Upload version with ADC calibration to AuxCmd3 RAM Bank 1.
    commandList=createCommandListRegisterConfig(zeros(Int32,1),true,r)
    uploadCommandList(commandList, "AuxCmd3", 1)

    selectAuxCommandLength("AuxCmd3", 0, length(commandList) - 1)

    #Select RAM Bank 1 for AuxCmd3 initially, so the ADC is calibrated.
    selectAuxCommandBank("PortA", "AuxCmd3", 1);

    setMaxTimeStep(SAMPLES_PER_DATA_BLOCK)
    setContinuousRunMode(false)
    runBoard()

    while (isRunning())
    end

    flushBoard()

    selectAuxCommandBank("PortA", "AuxCmd3", 0)

    nothing
    
end

function open_board(rhd::RHD2000)

    println("Scanning USB for Opal Kelly devices...")
    nDevices=ccall((:okFrontPanel_GetDeviceCount,lib), Int, (Ptr{Void},), rhd.board) 
    println("Found ", nDevices, " Opal Kelly device(s)")

    #Get Serial Number (I'm assuing there is only one device)
    serial=Array(Uint8,11)
    ccall((:okFrontPanel_GetDeviceListSerial,lib), Int32, (Ptr{Void}, Int, Ptr{UInt8}), rhd.board, 0,serial)
    serial[end]=0
    serialnumber=bytestring(pointer(serial))
    println("Serial number of device 0 is ", serialnumber)
    
    #Open by serial 
    if (ccall((:okFrontPanel_OpenBySerial, lib), Cint, (Ptr{Void},Ptr{UInt8}),rhd.board,serialnumber)!=0)
        println("Device could not be opened. Is one connected?")
        return -2
    end
    
    #configure on-board PLL
    ccall((:okFrontPanel_LoadDefaultPLLConfiguration,lib), Cint, (Ptr{Void},),rhd.board)

    return 1

end

function uploadFpgaBitfile(rhd::RHD2000)

    #upload configuration file
    errorcode=ccall((:okFrontPanel_ConfigureFPGA,lib),Cint,(Ptr{Void},Ptr{UInt8}),rhd.board,bit)

    #error checking goes here
    if errorcode==0
        println("FPGA configuration loaded.")
    else
        println("FPGA configuration failed.")
    end
    
    
    #Check if FrontPanel Support is enabled
    ccall((:okFrontPanel_IsFrontPanelEnabled,lib),Bool,(Ptr{Void},),rhd.board)

    UpdateWireOuts(rhd)
    
    boardId = GetWireOutValue(rhd,WireOutBoardId)
    boardVersion = GetWireOutValue(rhd,WireOutBoardVersion)
    if (boardId != RHYTHM_BOARD_ID)
        println("FPGA configuration does not support Rythm. Incorrect board ID: ", boardId)
    else
        println("Rhythm configuration file successfully loaded. Rhythm version number: ", boardVersion)
    end

    nothing
    
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

    nothing
       
end

function resetBoard(rhd::RHD2000)

    SetWireInValue(rhd,WireInResetRun, 0x01, 0x01)
    UpdateWireIns(rhd)
    SetWireInValue(rhd,WireInResetRun, 0x00, 0x01)
    UpdateWireIns(rhd)

    nothing
    
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

    nothing
                 
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

    nothing
    
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

    nothing

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

    nothing
    
end

function setContinuousRunMode(rhd::RHD2000,continuousMode)
    
    if continuousMode
        SetWireInValue(rhd,WireInResetRun,0x02,0x02)
    else
        SetWireInValue(rhd,WireInResetRun,0x00,0x02)
    end

    UpdateWireIns(rhd)

    nothing

end

function setMaxTimeStep(rhd::RHD2000,maxTimeStep)

    maxTimeStep=convert(UInt32, maxTimeStep)
    
    maxTimeStepLsb = maxTimeStep & 0x0000ffff
    maxTimeStepMsb = maxTimeStep & 0xffff0000

    SetWireInValue(rhd,WireInMaxTimeStepLsb,maxTimeStepLsb)
    SetWireInValue(rhd,WireInMaxTimeStepMsb,(maxTimeStepMsb >> 16))
    UpdateWireIns(rhd)

    nothing
    
end

function setCableLengthFeet(rhd::RHD2000,port, lengthInFeet::Float64)
    setCableLengthMeters(rhd,port, .3048 * lengthInFeet)

    nothing
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

    nothing
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

    nothing
    
end

function setDspSettle(rhd::RHD2000,enabled)

    SetWireInValue(rhd,WireInResetRun, (enabled ? 0x04 : 0x00), 0x04)
    UpdateWireIns(rhd)

    nothing
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

    nothing
end

function enableDataStream(rhd::RHD2000,stream::Int, enabled::Bool)
    
    #error checking goes here

    stream=convert(Int32,stream)
    if enabled
        if rhd.dataStreamEnabled[stream+1] == 0
            SetWireInValue(rhd,WireInDataStreamEn,0x0001 << stream, 0x0001 << stream)
            UpdateWireIns(rhd)
            rhd.dataStreamEnabled[stream+1] = 1;
            rhd.numDataStreams=rhd.numDataStreams+1;
        end
    else
        if rhd.dataStreamEnabled[stream+1] == 1
            SetWireInValue(rhd,WireInDataStreamEn,0x0000 << stream, 0x0001 << stream)
            UpdateWireIns(rhd)
            rhd.dataStreamEnabled[stream+1] = 0;
            rhd.numDataStream=rhd.numDataStreams-1;
        end
    end

    nothing
                
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

    nothing

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

    nothing
        
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

    nothing
    
end

function setDacManual(rhd::RHD2000,value)
    #error checking goes here

    SetWireInValue(rhd,WireInDacManual,value)
    UpdateWireIns(rhd)

    nothing
    
end

function setDacGain(rhd::RHD2000,gain)
    #error checking goes here

    
    SetWireInValue(rhd,WireInResetRun,gain << 13, 0xe000)
    UpdateWireIns(rhd)

    nothing
    
end

function setAudioNoiseSuppress(rhd::RHD2000,noiseSuppress)
    #error checking goes here

    SetWireInValue(rhd,WireInResetRun, noiseSuppress << 6, 0x1fc0)
    UpdateWireIns(rhd)

    nothing

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

    nothing
    
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
    return GetWireOutValue(rhd,WireOutNumWordsMsb)<<16+GetWireOutValue(rhd,WireOutNumWordsLsb)
    
end

function readDataBlocks(rhd::RHD2000,numBlocks::Int64)

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

        #Move data from usbBuffer to v
        fillFromUsbBuffer!(rhd,i)

        if rhd.cal==0

            cal!(rhd.s,rhd.v,rhd.buf,rhd.nums,true)

            rhd.cal=1
                      
        elseif rhd.cal==1

            cal!(rhd.s,rhd.v,rhd.buf,rhd.nums)
        
        elseif rhd.cal==2
            
            onlinesort!(rhd.s,rhd.v,rhd.buf,rhd.nums)

        end
        
    end

    return true
   
end


function calculateDataBlockSizeInWords(rhd::RHD2000)

    rhd.numWords = SAMPLES_PER_DATA_BLOCK * (4+2+(rhd.numDataStreams*36)+8+2)
                           
    nothing
    #4 = magic number; 2 = time stamp; 36 = (32 amp channels + 3 aux commands + 1 filler word); 8 = ADCs; 2 = TTL in/out

end

function calculateDataBlockSizeInBytes(rhd::RHD2000)

    rhd.numBytesPerBlock=convert(Int64,2 * rhd.numWords / SAMPLES_PER_DATA_BLOCK)

    nothing
    
end

function fillFromUsbBuffer!(rhd::RHD2000, blockIndex::Int64)
    
    index = blockIndex * rhd.numBytesPerBlock * SAMPLES_PER_DATA_BLOCK + 1
    
    index+=8
    for t=(1+blockIndex*SAMPLES_PER_DATA_BLOCK):(SAMPLES_PER_DATA_BLOCK+SAMPLES_PER_DATA_BLOCK*blockIndex)
        rhd.time[t]=convert(Int32,convertUsbTimeStamp(rhd.usbBuffer,index))
        index+=rhd.numBytesPerBlock
    end

    # 8 + 4 + 3*nDataStreams * 2 arrives at first amp channel (subtract 2 based on the way it is indexed)
    start=10+6*rhd.numDataStreams

    b=UInt32(0)
    for i=1:rhd.numDataStreams*32
        ind=start+i+i
        for j=1:SAMPLES_PER_DATA_BLOCK
            b=(convert(UInt32,rhd.usbBuffer[ind+1]) << 8) | (convert(UInt32,rhd.usbBuffer[ind]) << 0)
            rhd.v[j,i]=convert(Int64,b)
            ind+=rhd.numBytesPerBlock
        end
    end

    nothing
    
end
#=
function queueToFile(time::Array{Int32,1}, s::DArray{Sorting, 1, Array{Sorting,1}}, saveOut)

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
    
    nothing
    
end
=#
function convertUsbTimeStamp(usbBuffer::AbstractArray{UInt8,1}, index::Int64)

    x1 = convert(UInt32,usbBuffer[index])
    x2 = convert(UInt32,usbBuffer[index+1])
    x3 = convert(UInt32,usbBuffer[index+2])
    x4 = convert(UInt32,usbBuffer[index+3])

    return ((x4<<24) + (x3<<16) + (x2<<8) + (x1<<0))
end

function convertUsbWord(usbBuffer::AbstractArray{UInt8,1}, index::Int64)

    x1=convert(UInt32, usbBuffer[index])
    x2=convert(UInt32, usbBuffer[index+1])

    #The original C++ Rhythm API uses Int32, but Julia hasn't been playing nice with making sure that Int32s are type stable through calculations.
    return convert(Int64, ((x2<<8) | (x1<<0)))
    
end

#Library Wrapper Functions


function SetWireInValue(rhd::RHD2000, ep, val, mask = 0xffffffff)
    
    er=ccall((:okFrontPanel_SetWireInValue,lib),Cint,(Ptr{Void},Int,Culong,Culong),rhd.board,ep, val, mask)

    return er
end

function UpdateWireIns(rhd::RHD2000)

    ccall((:okFrontPanel_UpdateWireIns,lib),Void,(Ptr{Void},),rhd.board)

    nothing

end

function UpdateWireOuts(rhd::RHD2000)

    ccall((:okFrontPanel_UpdateWireOuts,lib),Void,(Ptr{Void},),rhd.board)

    nothing

end


function ActivateTriggerIn(rhd::RHD2000,epAddr::UInt8,bit::Int)
    
    er=ccall((:okFrontPanel_ActivateTriggerIn,lib),Cint,(Ptr{Void},Int32,Int32),rhd.board,epAddr,bit)

    return er

end

function GetWireOutValue(rhd::RHD2000,epAddr::UInt8)

    value = ccall((:okFrontPanel_GetWireOutValue,lib),Culong,(Ptr{Void},Int32),rhd.board,epAddr)

    return value

end

function ReadFromPipeOut(rhd::RHD2000,epAddr::UInt8, length, data::AbstractArray{UInt8,1})

    #CCall can fill Shared Arrays!
    ccall((:okFrontPanel_ReadFromPipeOut,lib),Clong,(Ptr{Void},Int32,Clong,Ptr{UInt8}),rhd.board,epAddr,length,data)

    return data
   
end
