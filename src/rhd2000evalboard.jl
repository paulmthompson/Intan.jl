
function RHD2164(port::AbstractString)
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
end

function RHD2132(port::AbstractString)
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
end

getlibrary(fpgas::Array{FPGA,1})=map(getlibrary,fpgas)

function getlibrary(fpga::FPGA)
    fpga.lib=Libdl.dlopen(intan_lib,Libdl.RTLD_NOW)
    fpga.board=ccall(Libdl.dlsym(fpga.lib,:okFrontPanel_Construct), Ptr{Void}, ())
    nothing
end

function init_board!(rhd::RHD2000,fpga::DArray{FPGA,1,Array{FPGA,1}})
    if rhd.debug.state==false
        map(open_board,fpga)
        map(uploadFpgaBitfile,fpga)
    else
        map(getlibrary,fpga)
    end

    @sync for p in procs(fpga)
        @async remotecall_fetch((d,sr,db)->init_board_helper(localpart(d),sr,db),p,fpga,rhd.sr,rhd.debug.state)
    end
    nothing
end

function init_board!(rhd::RHD2000,fpga::Array{FPGA,1})
    if rhd.debug.state==false
        map(open_board,fpga)
        map(uploadFpgaBitfile,fpga)
    else
        for thisfpga in fpga
            getlibrary(thisfpga)
        end
    end

    init_board_helper(fpga,rhd.sr,rhd.debug.state)

    nothing
end

function init_board_helper(fpgas::Array{FPGA,1},sr,mydebug=false)
    for fpga in fpgas
        init_board_helper(fpga,sr,mydebug)
    end
    nothing
end

function init_board_helper(fpga::FPGA,sr,mydebug=false)

    initialize_board(fpga,mydebug)

    #For 64 channel need two data streams, and data will come in
    #on the rising AND falling edges of SCLK
    if fpga.amps[1] == 255
        enableDataStream(fpga,0, false)
    else
        stream=0
        for i in fpga.amps
            enableDataStream(fpga,stream,true)
            if (OPEN_EPHYS)
                setDataSource(fpga,stream,i)
            end
            stream+=1
        end
    end

    #Enable DAC
    enableDac(fpga,0,true)

    calculateDataBlockSizeInWords(fpga)
    calculateDataBlockSizeInBytes(fpga)

    setSampleRate(fpga,sr,mydebug)
    println("Sample Rate set at ",fpga.sampleRate, " on board ", fpga.id)

    ledArray=[1,0,0,0,0,0,0,0]
    if (OPEN_EPHYS)
        setLedDisplay(fpga,ledArray)
    end

    #Set up an RHD2000 register object using this sample rate to optimize MUX-related register settings.
    fpga.r=CreateRHD2000Registers(Float64(fpga.sampleRate))

    #Upload version with no ADC calibration to AuxCmd3 RAM Bank 0.
    commandList=createCommandListRegisterConfig(zeros(Int32,1),false,fpga.r)
    uploadCommandList(fpga,commandList, "AuxCmd3", 0)

    #Upload version with ADC calibration to AuxCmd3 RAM Bank 1.
    commandList=createCommandListRegisterConfig(zeros(Int32,1),true,fpga.r)
    uploadCommandList(fpga,commandList, "AuxCmd3", 1)

    selectAuxCommandLength(fpga,"AuxCmd3", 0, length(commandList) - 1)

    if mydebug==false
        for port in ["PortA","PortB","PortC","PortD"]
            if check_port_streams(fpga,port)>0
                determine_delay(fpga,port)
                selectAuxCommandBank(fpga,port, "AuxCmd3", 1)
            end
        end
    end

    setMaxTimeStep(fpga,SAMPLES_PER_DATA_BLOCK)
    setContinuousRunMode(fpga,false)

    if mydebug==false
        runBoard(fpga)
        while (isRunning(fpga))
        end
        flushBoard(fpga)
    end

   for port in ["PortA","PortB","PortC","PortD"]
        if check_port_streams(fpga,port)>0
            selectAuxCommandBank(fpga,port, "AuxCmd3", 0)
        end
    end
    setContinuousRunMode(fpga,true)

    nothing
end

function open_board(fpga::FPGA)

    fpga.lib=Libdl.dlopen(intan_lib,Libdl.RTLD_NOW)
    fpga.board=ccall(Libdl.dlsym(fpga.lib,:okFrontPanel_Construct), Ptr{Void}, ())

    println("Scanning USB for Opal Kelly devices...")
    nDevices=ccall(Libdl.dlsym(fpga.lib,:okFrontPanel_GetDeviceCount), Int, (Ptr{Void},), fpga.board)
    println("Found ", nDevices, " Opal Kelly device(s)")

    #Get Serial Number
    serial=Array{UInt8}(11)
    ccall(Libdl.dlsym(fpga.lib,:okFrontPanel_GetDeviceListSerial), Int32, (Ptr{Void}, Int, Ptr{UInt8}), fpga.board, fpga.id,serial)
    serial[end]=0
    serialnumber=unsafe_string(pointer(serial))
    println("Serial number of device 0 is ", serialnumber)

    #Open by serial
    if (ccall(Libdl.dlsym(fpga.lib,:okFrontPanel_OpenBySerial), Cint, (Ptr{Void},Ptr{UInt8}),fpga.board,serialnumber)!=0)
        println("Device could not be opened. Is one connected?")
        return -2
    end

    #configure on-board PLL
    ccall(Libdl.dlsym(fpga.lib,:okFrontPanel_LoadDefaultPLLConfiguration), Cint, (Ptr{Void},),fpga.board)

    nothing
end

function open_board(fpgas::Array{FPGA,1})
    for fpga in fpgas
        open_board(fpga)
    end
    nothing
end

function uploadFpgaBitfile(fpgas::Array{FPGA,1})
    for fpga in fpgas
        uploadFpgaBitfile(fpga)
    end
    nothing
end

function uploadFpgaBitfile(rhd::FPGA)

    #upload configuration file
    if rhd.usb3
        if (OPEN_EPHYS)
            errorcode=ccall(Libdl.dlsym(rhd.lib,:okFrontPanel_ConfigureFPGA),Cint,(Ptr{Void},Ptr{UInt8}),rhd.board,usb3bit_open_ephys)
        else
            errorcode=ccall(Libdl.dlsym(rhd.lib,:okFrontPanel_ConfigureFPGA),Cint,(Ptr{Void},Ptr{UInt8}),rhd.board,usb3bit)
        end
    else
        errorcode=ccall(Libdl.dlsym(rhd.lib,:okFrontPanel_ConfigureFPGA),Cint,(Ptr{Void},Ptr{UInt8}),rhd.board,bit)
    end
    if errorcode==0
        println("FPGA configuration loaded.")
    else
        println("FPGA configuration failed.")
    end


    #Check if FrontPanel Support is enabled
    myenable = ccall(Libdl.dlsym(rhd.lib,:okFrontPanel_IsFrontPanelEnabled),Bool,(Ptr{Void},),rhd.board)

    UpdateWireOuts(rhd)
    boardId = GetWireOutValue(rhd,WireOutBoardId)
    boardVersion = GetWireOutValue(rhd,WireOutBoardVersion)

    if rhd.usb3
        if (OPEN_EPHYS)
            target_id = RHYTHM_BOARD_ID_OPENEPHYS
        else
	       target_id = 700
       end
    else
        target_id = RHYTHM_BOARD_ID
    end

    if (boardId != target_id)
        println("FPGA configuration does not support Rythm. Incorrect board ID: ", boardId)
    else
        println("Rhythm configuration file successfully loaded. Rhythm version number: ", boardVersion)
    end

    nothing
end

function initialize_board(fpgas::Array{FPGA,1})
    for fpga in fpgas
        initialize_board(fpga)
    end
    nothing
end

function initialize_board(rhd::FPGA,debug=false)

    resetBoard(rhd)

    if (!OPEN_EPHYS)
        readDigitalInManual(rhd)
    end

    setSampleRate(rhd,30000,debug)
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

    setCableLengthFeet(rhd,"PortA", 6.0)  # assume 6 ft cables
    setCableLengthFeet(rhd,"PortB", 6.0)
    setCableLengthFeet(rhd,"PortC", 6.0)
    setCableLengthFeet(rhd,"PortD", 6.0)

    setDspSettle(rhd,false)

    if (OPEN_EPHYS)
        setDataSource(rhd,0, PortA1)
        setDataSource(rhd,1, PortB1)
        setDataSource(rhd,2, PortC1)
        setDataSource(rhd,3, PortD1)
        setDataSource(rhd,4, PortA2)
        setDataSource(rhd,5, PortB2)
        setDataSource(rhd,6, PortC2)
        setDataSource(rhd,7, PortD2)

        if rhd.usb3
            setDataSource(rhd,8, PortA1)
            setDataSource(rhd,9, PortB1)
            setDataSource(rhd,10, PortC1)
            setDataSource(rhd,11, PortD1)
            setDataSource(rhd,12, PortA2)
            setDataSource(rhd,13, PortB2)
            setDataSource(rhd,14, PortC2)
            setDataSource(rhd,15, PortD2)
        end
    else
        SetWireInValue(rhd,WireInDataStreamEn, 0x00000000);
        UpdateWireIns(rhd);
    end


    #remember that julia indexes with 1's instead of 0's to start an array
    enableDataStream(rhd,0, true)
    for i=1:(MAX_NUM_DATA_STREAMS-1)
        enableDataStream(rhd,i,false)
    end

    clearTtlOut(rhd)

    for i=0:7; enableDac(rhd,i, false); end
    for i=0:7; selectDacDataStream(rhd,i, 0); end
    for i=0:7; selectDacDataChannel(rhd,i, 0); end
    #for i=0:7; selectDacDataStream(rhd,i, 8); end
    #selectDacDataChannel(rhd,0, 0)
    #selectDacDataChannel(rhd,1, 1)
    #for i=2:7; selectDacDataChannel(rhd,i, 0); end

    setDacManual(rhd,32768)    # midrange value = 0 V

    setDacGain(rhd,0)
    setAudioNoiseSuppress(rhd,0)

    setTtlMode(rhd,0)

    for i=0:7; setDacThreshold(rhd,i, 32768, true); end

    enableExternalFastSettle(rhd,false)
    setExternalFastSettleChannel(rhd,15)

    enableExternalDigOut(rhd,"PortA", false)
    enableExternalDigOut(rhd,"PortB", false)
    enableExternalDigOut(rhd,"PortC", false)
    enableExternalDigOut(rhd,"PortD", false)
    setExternalDigOutChannel(rhd,"PortA", 0)
    setExternalDigOutChannel(rhd,"PortB", 0)
    setExternalDigOutChannel(rhd,"PortC", 0)
    setExternalDigOutChannel(rhd,"PortD", 0)

    if (OPEN_EPHYS)
        enableBoardLeds(rhd,true);
    end

    nothing
end

function resetBoard(rhd::FPGA)

    SetWireInValue(rhd,WireInResetRun, 0x01, 0x01)
    UpdateWireIns(rhd)
    SetWireInValue(rhd,WireInResetRun, 0x00, 0x01)
    UpdateWireIns(rhd)


    if rhd.usb3
       SetWireInValue(rhd,WireInMultiUse, div(USB3_BLOCK_SIZE,4))
       UpdateWireIns(rhd)
       if (OPEN_EPHYS)
           ActivateTriggerIn(rhd,TrigInOpenEphys,16)
       else
           ActivateTriggerIn(rhd,TrigInConfig,9)
       end

       SetWireInValue(rhd,WireInMultiUse, DDR_BURST_LENGTH)
       UpdateWireIns(rhd)
       if (OPEN_EPHYS)
           ActivateTriggerIn(rhd,TrigInOpenEphys,17)
       else
           ActivateTriggerIn(rhd,TrigInConfig,10)
       end
    end

    nothing
end

function setSampleRate(rhd::FPGA,newSampleRate::Int64,debug=false)

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
    if !debug
        while !isDcmProgDone(rhd)
        end
    end

    #Reprogram clock synthesizer

    SetWireInValue(rhd,WireInDataFreqPll,(256 * convert(Culong,M) + convert(Culong,D)))
    UpdateWireIns(rhd)
    if (OPEN_EPHYS)
        ActivateTriggerIn(rhd,TrigInDcmProg,0)
    else
        ActivateTriggerIn(rhd,TrigInConfig,0)
    end

    #Wait for DataClkLocked = 1 before allowing data acquisition to continue
    if !debug
        while !isDataClockLocked(rhd)
        end
    end

    nothing
end

function isDcmProgDone(rhd::FPGA)

    UpdateWireOuts(rhd)
    value=GetWireOutValue(rhd,WireOutDataClkLocked)
    return ((value & 0x0002) > 1)
end

function isDataClockLocked(rhd::FPGA)

    UpdateWireOuts(rhd)
    value=GetWireOutValue(rhd,WireOutDataClkLocked)
    return ((value & 0x0001) > 0)
end

function uploadCommandList(rhd::FPGA,commandList, auxCommandSlot, bank)

    #error checking goes here

    for i=1:length(commandList)

        SetWireInValue(rhd,WireInCmdRamData, commandList[i])
        SetWireInValue(rhd,WireInCmdRamAddr, i-1)
        SetWireInValue(rhd,WireInCmdRamBank, bank)
        UpdateWireIns(rhd)
        if auxCommandSlot == "AuxCmd1"
		    if (OPEN_EPHYS)
                ActivateTriggerIn(rhd,TrigInRamWrite,0)
		    else
	            ActivateTriggerIn(rhd,TrigInConfig,1)
	        end
        elseif auxCommandSlot == "AuxCmd2"
            if (OPEN_EPHYS)
                ActivateTriggerIn(rhd,TrigInRamWrite,1)
            else
                ActivateTriggerIn(rhd,TrigInConfig,2)
            end
        elseif auxCommandSlot == "AuxCmd3"
            if (OPEN_EPHYS)
                ActivateTriggerIn(rhd,TrigInRamWrite,2)
            else
                ActivateTriggerIn(rhd,TrigInConfig,3)
            end
        end
    end

    nothing
end

function selectAuxCommandBank(rhd::FPGA,port, commandslot, bank)

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

function selectAuxCommandLength(rhd::FPGA,commandslot,loopIndex,endIndex)

    #Error checking goes here

    if commandslot=="AuxCmd1"
        if (OPEN_EPHYS)
            SetWireInValue(rhd,WireInAuxCmdLoop1,loopIndex)
            SetWireInValue(rhd,WireInAuxCmdLength1,endIndex)
        else
            SetWireInValue(rhd,WireInAuxCmdLoop, loopIndex, 0x000003ff);
            SetWireInValue(rhd,WireInAuxCmdLength, endIndex, 0x000003ff);
        end
    elseif commandslot=="AuxCmd2"
        if (OPEN_EPHYS)
            SetWireInValue(rhd,WireInAuxCmdLoop2,loopIndex)
            SetWireInValue(rhd,WireInAuxCmdLength2,endIndex)
        else
            SetWireInValue(rhd, WireInAuxCmdLoop, loopIndex << 10, 0x000003ff << 10);
            SetWireInValue(rhd, WireInAuxCmdLength, endIndex << 10, 0x000003ff << 10);
        end
    elseif commandslot=="AuxCmd3"
        if (OPEN_EPHYS)
            SetWireInValue(rhd,WireInAuxCmdLoop3,loopIndex)
            SetWireInValue(rhd,WireInAuxCmdLength3,endIndex)
        else
            SetWireInValue(rhd,WireInAuxCmdLoop, loopIndex << 20, 0x000003ff << 20);
            SetWireInValue(rhd,WireInAuxCmdLength, endIndex << 20, 0x000003ff << 20);
        end
    end

    UpdateWireIns(rhd)

    nothing
end

function setContinuousRunMode(rhd::FPGA,continuousMode)

    if continuousMode
        SetWireInValue(rhd,WireInResetRun,0x02,0x02)
    else
        SetWireInValue(rhd,WireInResetRun,0x00,0x02)
    end

    UpdateWireIns(rhd)

    nothing
end

function setMaxTimeStep(rhd::FPGA,maxTimeStep)

    if (OPEN_EPHYS)
        maxTimeStep=convert(UInt32, maxTimeStep)

        maxTimeStepLsb = maxTimeStep & 0x0000ffff
        maxTimeStepMsb = maxTimeStep & 0xffff0000

        SetWireInValue(rhd,WireInMaxTimeStepLsb,maxTimeStepLsb)
        SetWireInValue(rhd,WireInMaxTimeStepMsb,(maxTimeStepMsb >> 16))
    else
        SetWireInValue(rhd,WireInMaxTimeStep, maxTimeStep);
    end
    UpdateWireIns(rhd)

    nothing
end

setCableLengthFeet(rhd::FPGA,port,lengthInFeet::Float64)=setCableLengthMeters(rhd,port,.3048*lengthInFeet)

function setCableLengthMeters(rhd::FPGA,port, lengthInMeters::Float64)

    tStep=1.0 / (2800.0 * rhd.sampleRate)

    distance = 2.0 * lengthInMeters

    timeDelay = (distance / cableVelocity) + xilinxLvdsOutputDelay + rhd2000Delay + xilinxLvdsInputDelay + misoSettleTime

    delay = convert(Int32,floor(((timeDelay / tStep) + 1.0) +0.5))

    if delay < 1
        delay=1
    end

    setCableDelay(rhd,port, delay)
    nothing
end

function estimateCableLengthMeters(fpga,delay)

    tStep=1.0 / (2800.0 * fpga.sampleRate)
    cableVelocity = 0.555 * speedOfLight
    distance = ((delay - 1.0) * tStep - (xilinxLvdsOutputDelay + rhd2000Delay + xilinxLvdsInputDelay + misoSettleTime))
    if distance <0.0
        distance = 0.0
    end
    distance
end

function approxCableLengthFeet(fpga,delay)
    estimateCableLengthMeters(fpga,delay) * 3.2808
end

function setCableDelay(rhd::FPGA,port, delay)

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

    SetWireInValue(rhd,WireInMisoDelay, delay << bitShift, 0x0000000f << bitShift)
    UpdateWireIns(rhd)

    nothing
end

setDspSettle(rhd::FPGA,enabled)=(SetWireInValue(rhd,WireInResetRun,(enabled ? 0x04 : 0x00),0x04);UpdateWireIns(rhd))

function setDataSource(rhd::FPGA,stream, dataSource)

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
elseif stream==8
	endPoint=WireInDataStreamSel1234
	bitShift=16
elseif stream==9
	endPoint=WireInDataStreamSel1234
	bitShift=20
elseif stream==10
	endPoint=WireInDataStreamSel1234
	bitShift=24
elseif stream==11
	endPoint=WireInDataStreamSel1234
	bitShift=28
elseif stream==12
	endPoint=WireInDataStreamSel5678
	bitShift=16
elseif stream==13
	endPoint=WireInDataStreamSel5678
	bitShift=20
elseif stream==14
	endPoint=WireInDataStreamSel5678
	bitShift=24
elseif stream==15
	endPoint=WireInDataStreamSel5678
	bitShift=28
    end

    bitShift=convert(Int32,bitShift)
    SetWireInValue(rhd,endPoint,(dataSource << bitShift), (0x000f << bitShift))
    UpdateWireIns(rhd)

    nothing
end

function enableDataStream(rhd::FPGA,stream::Int, enabled::Bool)

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
            rhd.numDataStreams=rhd.numDataStreams-1;
        end
    end

    nothing
end

function enableDac(rhd::FPGA,dacChannel::Int,enabled::Bool)

    #error checking goes here

    if rhd.usb3
        dacEnMask = 0x0800
    else
        dacEnMask = 0x0200
    end


    if dacChannel == 0
        SetWireInValue(rhd,WireInDacSource1,(enabled ? dacEnMask : 0x0000), 0x0800)
    elseif dacChannel == 1
        SetWireInValue(rhd,WireInDacSource2,(enabled ? dacEnMask : 0x0000), 0x0800)
    elseif dacChannel == 2
        SetWireInValue(rhd,WireInDacSource3,(enabled ? dacEnMask : 0x0000), 0x0800)
    elseif dacChannel == 3
        SetWireInValue(rhd,WireInDacSource4,(enabled ? dacEnMask : 0x0000), 0x0800)
    elseif dacChannel == 4
        SetWireInValue(rhd,WireInDacSource5,(enabled ? dacEnMask : 0x0000), 0x0800)
    elseif dacChannel == 5
        SetWireInValue(rhd,WireInDacSource6,(enabled ? dacEnMask : 0x0000), 0x0800)
    elseif dacChannel == 6
        SetWireInValue(rhd,WireInDacSource7,(enabled ? dacEnMask : 0x0000), 0x0800)
    elseif dacChannel == 7
        SetWireInValue(rhd,WireInDacSource8,(enabled ? dacEnMask : 0x0000), 0x0800)
    end

    UpdateWireIns(rhd)

    nothing
end

function selectDacDataStream(rhd::FPGA,dacChannel, stream)
    #error checking goes here

    if rhd.usb3
        if (OPEN_EPHYS)
            dacStreamMask = 0x03e0
        else
            dacStreamMask = 0x07e0
        end        
    else
        dacStreamMask = 0x01e0
    end

    if dacChannel == 0
         SetWireInValue(rhd,WireInDacSource1, stream << 5, dacStreamMask)
    elseif dacChannel == 1
         SetWireInValue(rhd,WireInDacSource2, stream << 5, dacStreamMask)
    elseif dacChannel == 2
         SetWireInValue(rhd,WireInDacSource3, stream << 5, dacStreamMask)
    elseif dacChannel == 3
         SetWireInValue(rhd,WireInDacSource4, stream << 5, dacStreamMask)
    elseif dacChannel == 4
         SetWireInValue(rhd,WireInDacSource5, stream << 5, dacStreamMask)
    elseif dacChannel == 5
         SetWireInValue(rhd,WireInDacSource6, stream << 5, dacStreamMask)
    elseif dacChannel == 6
         SetWireInValue(rhd,WireInDacSource7, stream << 5, dacStreamMask)
    elseif dacChannel == 7
         SetWireInValue(rhd,WireInDacSource8, stream << 5, dacStreamMask)
    end

    UpdateWireIns(rhd)

    nothing
end

function selectDacDataChannel(rhd::FPGA,dacChannel::Int, dataChannel)
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

setDacManual(rhd::FPGA,value)=(SetWireInValue(rhd,WireInDacManual,value);UpdateWireIns(rhd))

setDacGain(rhd::FPGA,gain)=(SetWireInValue(rhd,WireInResetRun,gain<<13,0xe000);UpdateWireIns(rhd))

setAudioNoiseSuppress(rhd::FPGA,noiseSuppress)=(SetWireInValue(rhd,WireInResetRun,noiseSuppress<<6,0x1fc0);UpdateWireIns(rhd))

setTtlMode(rhd::FPGA,mode)=(SetWireInValue(rhd,WireInResetRun,mode<<3,0x0008);UpdateWireIns(rhd))

clearTtlOut(rhd::FPGA)=(SetWireInValue(rhd,WireInTtlOut, 0x0000);UpdateWireIns(rhd))

function setDacThreshold(rhd::FPGA,dacChannel, threshold, trigPolarity)

    #error checking goes here

    #Set threshold level
    SetWireInValue(rhd,WireInMultiUse,threshold)
    UpdateWireIns(rhd)
    if (OPEN_EPHYS)
        ActivateTriggerIn(rhd,TrigInDacThresh, dacChannel)
    else
        ActivateTriggerIn(rhd,TrigInDacConfig, dacChannel)
    end

    #Set threshold polarity
    SetWireInValue(rhd,WireInMultiUse, (trigPolarity ? 1 : 0))
    UpdateWireIns(rhd)
    if (OPEN_EPHYS)
        ActivateTriggerIn(rhd,TrigInDacThresh, dacChannel+8)
    else
        ActivateTriggerIn(rhd,TrigInDacConfig, dacChannel+8)
    end

    nothing
end

function enableExternalFastSettle(rhd::FPGA,enable)

    SetWireInValue(rhd,WireInMultiUse, (enable ? 1 : 0))
    UpdateWireIns(rhd)
    if (OPEN_EPHYS)
        ActivateTriggerIn(rhd,TrigInExtFastSettle,0)
    else
        ActivateTriggerIn(rhd,TrigInConfig,6)
    end


    nothing
end

function setExternalFastSettleChannel(rhd::FPGA,channel)

    #error checking goes here

    SetWireInValue(rhd,WireInMultiUse,channel)
    UpdateWireIns(rhd)
    if (OPEN_EPHYS)
        ActivateTriggerIn(rhd,TrigInExtFastSettle,1)
    else
        ActivateTriggerIn(rhd,TrigInConfig,7)
    end
end

function enableExternalDigOut(rhd::FPGA,port, enable)

    SetWireInValue(rhd,WireInMultiUse, (enable ? 1 : 0))
    UpdateWireIns(rhd)

    if port=="PortA"
        if (OPEN_EPHYS)
            ActivateTriggerIn(rhd,TrigInExtDigOut,0)
        else
            ActivateTriggerIn(rhd,TrigInConfig,16)
        end
    elseif port=="PortB"
        if (OPEN_EPHYS)
            ActivateTriggerIn(rhd,TrigInExtDigOut,1)
        else
            ActivateTriggerIn(rhd,TrigInConfig,17)
        end
    elseif port=="PortC"
        if (OPEN_EPHYS)
            ActivateTriggerIn(rhd,TrigInExtDigOut,2)
        else
            ActivateTriggerIn(rhd,TrigInConfig,18)
        end
    elseif port=="PortD"
        if (OPEN_EPHYS)
            ActivateTriggerIn(rhd,TrigInExtDigOut,3)
        else
            ActivateTriggerIn(rhd,TrigInConfig,19)
        end
    end

    nothing
end

function setExternalDigOutChannel(rhd::FPGA,port, channel)

    SetWireInValue(rhd,WireInMultiUse,channel)
    UpdateWireIns(rhd)

    if port=="PortA"
        if (OPEN_EPHYS)
            ActivateTriggerIn(rhd,TrigInExtDigOut,4)
        else
            ActivateTriggerIn(rhd,TrigInConfig,24)
        end
    elseif port=="PortB"
        if (OPEN_EPHYS)
            ActivateTriggerIn(rhd,TrigInExtDigOut,5)
        else
            ActivateTriggerIn(rhd,TrigInConfig,25)
        end
    elseif port=="PortC"
        if (OPEN_EPHYS)
            ActivateTriggerIn(rhd,TrigInExtDigOut,6)
        else
            ActivateTriggerIn(rhd,TrigInConfig,26)
        end
    elseif port=="PortD"
        if (OPEN_EPHYS)
            ActivateTriggerIn(rhd,TrigInExtDigOut,7)
        else
            ActivateTriggerIn(rhd,TrigInConfig,27)
        end
    end

    nothing
end

function getTtlIn(rhd::FPGA,ttlInArray)

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

function setTtlOut(rhd::FPGA,ttlOutArray)

    ttlOut=Int32(0)
    for i=1:16
        if ttlOutArray[i]>0
            ttlOut += (1<< (i-1))
        end
    end

    SetWireInValue(rhd,WireInTtlOut,ttlOut)
    UpdateWireIns(rhd)
    nothing
end

function sendTimePulse(fpga::FPGA,val::Bool)

    if val==true
        fpga.ttloutput += (1 << (16-1))
    else
        fpga.ttloutput -= (1 << (16-1))
    end

    SetWireInValue(fpga,WireInTtlOut,fpga.ttloutput)
    UpdateWireIns(fpga)
    nothing
end

function setLedDisplay(rhd::FPGA,ledArray)

    ledOut=0
    for i=1:8
        if ledArray[i]>0
            ledOut += 1 << (i-1)
        end
    end

    SetWireInValue(rhd,WireInLedDisplay_openephys,ledOut)
    UpdateWireIns(rhd)

    nothing
end

runBoard(fpgas::Array{FPGA,1})=map(runBoard,fpgas)

runBoard(rhd::FPGA)=ActivateTriggerIn(rhd,TrigInSpiStart,0)

function isRunning(rhd::FPGA)

    UpdateWireOuts(rhd)
    value=GetWireOutValue(rhd,WireOutSpiRunning)

    if ((value & 0x01) == 0)
        return false
    else
        return true
    end
end

function flushBoard(rhd::FPGA)

    if !rhd.usb3
        while (numWordsInFifo(rhd) >= (USB_BUFFER_SIZE/2))
            ReadFromPipeOut(rhd,PipeOutData, USB_BUFFER_SIZE, rhd.usbBuffer)
        end

        while (numWordsInFifo(rhd) > 0)
            ReadFromPipeOut(rhd,PipeOutData, (2 * numWordsInFifo(rhd)), rhd.usbBuffer)
        end
    else
        SetWireInValue(rhd,WireInResetRun, 1<<16, 1<<16)
        UpdateWireIns(rhd)
        if (OPEN_EPHYS)
            while (numWordsInFifo(rhd) > 0)
                ReadFromBlockPipeOut(rhd,PipeOutData, USB3_BLOCK_SIZE, rhd.usbBuffer)
            end
        else
            while (numWordsInFifo(rhd) > USB_BUFFER_SIZE / 2)
                ReadFromBlockPipeOut(rhd,PipeOutData,USB_BUFFER_SIZE,rhd.usbBuffer)
            end
            while (numWordsInFifo(rhd) > 0)
                ReadFromBlockPipeOut(rhd,PipeOutData,USB3_BLOCK_SIZE * max(div(2*numWordsInFifo(rhd) , USB3_BLOCK_SIZE),1),rhd.usbBuffer)
            end
        end
        SetWireInValue(rhd,WireInResetRun,0<<16, 1<<16)
        UpdateWireIns(rhd)
    end
    nothing
end

function readDigitalInManual(rhd::FPGA)

    spiPortPresent = falses(8)
    userId=falses(3);
    serialId=falses(4);

    UpdateWireOuts(rhd);

    expanderBoardDetected = (GetWireOutValue(rhd,WireOutSerialDigitalIn) & 0x04) != 0;
    expanderBoardIdNumber = (GetWireOutValue(rhd,WireOutSerialDigitalIn) & 0x08)

    SetWireInValue(rhd,WireInSerialDigitalInCntl, 2)
    UpdateWireIns(rhd)
    SetWireInValue(rhd,WireInSerialDigitalInCntl, 0)  # Load digital in shift registers on falling edge of serial_LOAD
    UpdateWireIns(rhd)

    UpdateWireOuts(rhd);
    spiPortPresent[8] = GetWireOutValue(rhd,WireOutSerialDigitalIn) & 0x01;

    SetWireInValue(rhd,WireInSerialDigitalInCntl, 1);
    UpdateWireIns(rhd);
    SetWireInValue(rhd,WireInSerialDigitalInCntl, 0);
    UpdateWireIns(rhd);

    UpdateWireOuts(rhd);
    spiPortPresent[7] = GetWireOutValue(rhd,WireOutSerialDigitalIn) & 0x01;

    SetWireInValue(rhd,WireInSerialDigitalInCntl, 1);
    UpdateWireIns(rhd);
    SetWireInValue(rhd,WireInSerialDigitalInCntl, 0);
    UpdateWireIns(rhd);

    UpdateWireOuts(rhd);
    spiPortPresent[6] = GetWireOutValue(rhd,WireOutSerialDigitalIn) & 0x01;

    SetWireInValue(rhd,WireInSerialDigitalInCntl, 1);
    UpdateWireIns(rhd);
    SetWireInValue(rhd,WireInSerialDigitalInCntl, 0);
    UpdateWireIns(rhd);

    UpdateWireOuts(rhd);
    spiPortPresent[5] = GetWireOutValue(rhd,WireOutSerialDigitalIn) & 0x01;

    SetWireInValue(rhd,WireInSerialDigitalInCntl, 1);
    UpdateWireIns(rhd);
    SetWireInValue(rhd,WireInSerialDigitalInCntl, 0);
    UpdateWireIns(rhd);

    UpdateWireOuts(rhd);
    spiPortPresent[4] = GetWireOutValue(rhd,WireOutSerialDigitalIn) & 0x01;

    SetWireInValue(rhd,WireInSerialDigitalInCntl, 1);
    UpdateWireIns(rhd);
    SetWireInValue(rhd,WireInSerialDigitalInCntl, 0);
    UpdateWireIns(rhd);

    UpdateWireOuts(rhd);
    spiPortPresent[3] = GetWireOutValue(rhd,WireOutSerialDigitalIn) & 0x01;

    SetWireInValue(rhd,WireInSerialDigitalInCntl, 1);
    UpdateWireIns(rhd);
    SetWireInValue(rhd,WireInSerialDigitalInCntl, 0);
    UpdateWireIns(rhd);

    UpdateWireOuts(rhd);
    spiPortPresent[2] = GetWireOutValue(rhd,WireOutSerialDigitalIn) & 0x01;

    SetWireInValue(rhd,WireInSerialDigitalInCntl, 1);
    UpdateWireIns(rhd);
    SetWireInValue(rhd,WireInSerialDigitalInCntl, 0);
    UpdateWireIns(rhd);

    UpdateWireOuts(rhd);
    spiPortPresent[1] = GetWireOutValue(rhd,WireOutSerialDigitalIn) & 0x01;

    SetWireInValue(rhd,WireInSerialDigitalInCntl, 1);
    UpdateWireIns(rhd);
    SetWireInValue(rhd,WireInSerialDigitalInCntl, 0);
    UpdateWireIns(rhd);

    UpdateWireOuts(rhd);
    digOutVoltageLevel = GetWireOutValue(rhd,WireOutSerialDigitalIn) & 0x01;

    SetWireInValue(rhd,WireInSerialDigitalInCntl, 1);
    UpdateWireIns(rhd);
    SetWireInValue(rhd,WireInSerialDigitalInCntl, 0);
    UpdateWireIns(rhd);

    UpdateWireOuts(rhd);
    userId[3] = GetWireOutValue(rhd,WireOutSerialDigitalIn) & 0x01;

    SetWireInValue(rhd,WireInSerialDigitalInCntl, 1);
    UpdateWireIns(rhd);
    SetWireInValue(rhd,WireInSerialDigitalInCntl, 0);
    UpdateWireIns(rhd);

    UpdateWireOuts(rhd);
    userId[2] = GetWireOutValue(rhd,WireOutSerialDigitalIn) & 0x01;

    SetWireInValue(rhd,WireInSerialDigitalInCntl, 1);
    UpdateWireIns(rhd);
    SetWireInValue(rhd,WireInSerialDigitalInCntl, 0);
    UpdateWireIns(rhd);

    UpdateWireOuts(rhd);
    userId[1] = GetWireOutValue(rhd,WireOutSerialDigitalIn) & 0x01;

    SetWireInValue(rhd,WireInSerialDigitalInCntl, 1);
    UpdateWireIns(rhd);
    SetWireInValue(rhd,WireInSerialDigitalInCntl, 0);
    UpdateWireIns(rhd);

    UpdateWireOuts(rhd);
    serialId[4] = GetWireOutValue(rhd,WireOutSerialDigitalIn) & 0x01;

    SetWireInValue(rhd,WireInSerialDigitalInCntl, 1);
    UpdateWireIns(rhd);
    SetWireInValue(rhd,WireInSerialDigitalInCntl, 0);
    UpdateWireIns(rhd);

    UpdateWireOuts(rhd);
    serialId[3] = GetWireOutValue(rhd,WireOutSerialDigitalIn) & 0x01;

    SetWireInValue(rhd,WireInSerialDigitalInCntl, 1);
    UpdateWireIns(rhd);
    SetWireInValue(rhd,WireInSerialDigitalInCntl, 0);
    UpdateWireIns(rhd);

    UpdateWireOuts(rhd);
    serialId[2] = GetWireOutValue(rhd,WireOutSerialDigitalIn) & 0x01;

    SetWireInValue(rhd,WireInSerialDigitalInCntl, 1);
    UpdateWireIns(rhd);
    SetWireInValue(rhd,WireInSerialDigitalInCntl, 0);
    UpdateWireIns(rhd);

    UpdateWireOuts(rhd);
    serialId[1] = GetWireOutValue(rhd,WireOutSerialDigitalIn) & 0x01;

    numPorts = 4;
    for i=5:8
        if (spiPortPresent[i])
            numPorts = 8;
        end
    end

    println(string("expanderBoardDetected: ", expanderBoardDetected))
    println(string("expanderBoardId: " , expanderBoardIdNumber ))

    return numPorts;
end

function numWordsInFifo(rhd::FPGA)

    UpdateWireOuts(rhd)

    if (OPEN_EPHYS)
        GetWireOutValue(rhd,WireOutNumWordsMsb)<<16+GetWireOutValue(rhd,WireOutNumWordsLsb)
    else
        GetWireOutValue(rhd,WireOutNumWords)
    end
end

function compareNumWords(fpgas::Array{FPGA,1})
    out=false
    for fpga in fpgas
        out=out|compareNumWords(fpga)
    end
    out
end

compareNumWords(fpga::FPGA)=numWordsInFifo(fpga) < fpga.numWords

function calibrate_parallel(fpga,s,v,buf,nums,mytime,calnum)

    @sync begin
        for p in procs(fpga)
            @async remotecall_wait((ff,ss)->readDataBlocks_cal(localpart(ff),localpart(ss),v,buf,nums,mytime),p,fpga,s)
        end
    end
    nothing
end

function onlinesort_parallel(fpga,s,v,buf,nums,mytime)

    @sync begin
        for p in procs(fpga)
            @async remotecall_wait((ff,ss)->readDataBlocks_on(localpart(ff),localpart(ss),v,buf,nums,mytime),p,fpga,s)
        end
    end
    nothing
end

function readDataBlocks_cal(fpgas::Array{FPGA,1},s,v,buf,nums,mytime,calnum)

    readDataBlocks_cal(fpgas[1],s,v,buf,nums,mytime,calnum)
    nothing
end

function readDataBlocks_cal(fpga::FPGA,s,v,buf,nums,mytime,calnum)

    #block until there are enough words
    while compareNumWords(fpga)
    end

    if fpga.usb3
       ReadFromBlockPipeOut(fpga,PipeOutData,convert(Clong,fpga.numBytesPerBlock),fpga.usbBuffer)
    else
	   ReadFromPipeOut(fpga,PipeOutData,convert(Clong,fpga.numBytesPerBlock),fpga.usbBuffer)
    end
    fillFromUsbBuffer!(fpga,0,v,mytime)

    #Reference Channels

    cal!(s,v,buf,nums,calnum)

    nothing
end

function readDataBlocks_on(fpgas::Array{FPGA,1},s,v,buf,nums,mytime)

    readDataBlocks_on(fpgas[1],s,v,buf,nums,mytime)
    nothing
end

function readDataBlocks_on(fpga::FPGA,s,v,buf,nums,mytime)

    #block until there are enough words
    while compareNumWords(fpga)
    end

    if fpga.usb3
       ReadFromBlockPipeOut(fpga,PipeOutData,convert(Clong,fpga.numBytesPerBlock),fpga.usbBuffer)
    else
	ReadFromPipeOut(fpga,PipeOutData,convert(Clong,fpga.numBytesPerBlock),fpga.usbBuffer)
    end

    fillFromUsbBuffer!(fpga,0,v,mytime)

    #Reference Channels

    onlinesort!(s,v,buf,nums)

    nothing
end

function cal_update(rhd::RHD2000)

    if rhd.cal==0

        rhd.cal=1

    elseif rhd.cal<3

        if rhd.reads>20
            #rhd.cal=2
            rhd.cal=3

        end

    elseif rhd.cal==3

    end

    rhd.reads+=1

    nothing
end

function readDataBlocks(rhd::RHD2000,numBlocks::Int64,s,myfpga::Array{FPGA,1})

    if compareNumWords(myfpga)
        return false
    end

    #=
    if (numBytesToRead > USB_BUFFER_SIZE)
        println("USB buffer size exceeded")
        return false
    end
    =#

    numRead=0

    numBytesToRead = myfpga[1].numBytesPerBlock * numBlocks
    if length(myfpga)>1
        for fpga in myfpga
            ReadFromPipeOut(fpga,PipeOutData, convert(Clong, fpga.numBytesPerBlock * numBlocks), fpga.usbBuffer)
        end
        numRead=numBytesToRead
    else
        if myfpga[1].usb3
            numRead=ReadFromBlockPipeOut(myfpga[1],PipeOutData, convert(Clong, numBytesToRead), myfpga[1].usbBuffer)
        else
            numRead=ReadFromPipeOut(myfpga[1],PipeOutData, convert(Clong, numBytesToRead), myfpga[1].usbBuffer)
        end
    end

    for i=0:(numBlocks-1)

        #Move data from usbBuffer to v

        fillFromUsbBuffer!(myfpga,i,rhd.v,rhd.time)

        #If analog here, we want to move adc number x into voltage channels
        #
        if myfpga[1].amps[1] == 255
            try
                rhd.v[:,1] = myfpga[1].adc[:,2] - 2556 #open ephys special
            catch
                for jj=1:size(rhd.v,1)
                    if abs(myfpga[1].adc[jj,2] - 2556)>typemax(Int16)
                        rhd.v[jj,1] = typemax(Int16) * sign(myfpga[1].adc[jj,2] - 2556)
                    else
                        rhd.v[jj,1] = myfpga[1].adc[jj,2] - 2556
                    end
                end
            end
        end

        for j=1:size(rhd.v,2)
            if rhd.refs[j]>0
                for k=1:size(rhd.v,1)
                    rhd.v[k,j]=rhd.v[k,j]-rhd.v[k,rhd.refs[j]]
                end
            end
        end

        #Filtering
        for i=1:length(rhd.filts)
            for j=1:length(rhd.filts[i])
                apply_filter(rhd,rhd.filts[i][j],rhd.filts[i][j].chan)
            end
        end

        #Sorting
        applySorting(rhd,s)
    end

    return true
end

function applySorting(rhd::RHD2000,s)

    if rhd.cal==0

        cal!(s,rhd.v,rhd.buf,rhd.nums,rhd.cal)
        rhd.cal=1

    elseif rhd.cal<3

        cal!(s,rhd.v,rhd.buf,rhd.nums,rhd.cal)

        if rhd.reads>20
            #rhd.cal=2
            rhd.cal=3
        end

    elseif rhd.cal==3

        onlinesort!(s,rhd.v,rhd.buf,rhd.nums)
    end

    rhd.reads+=1
    nothing
end

function enableBoardLeds(rhd::FPGA,enable)

    SetWireInValue(rhd,WireInMultiUse, enable ? 1 : 0)
	UpdateWireIns(rhd)
    ActivateTriggerIn(rhd,TrigInOpenEphys, 0)

end

function setClockDivider(rhd,divide_factor)

    SetWireInValue(rhd,WireInMultiUse, divide_factor);
	UpdateWireIns(rhd);
    ActivateTriggerIn(rhd,TrigInOpenEphys, 1);

end

function calculateDataBlockSizeInWords(rhd::FPGA)
    #rhd.numWords = SAMPLES_PER_DATA_BLOCK * (4+2+(rhd.numDataStreams*36)+8+2)
    rhd.numWords = SAMPLES_PER_DATA_BLOCK * (4+2+(rhd.numDataStreams*36) + 8+2)
    nothing
    #4 = magic number; 2 = time stamp; 36 = (32 amp channels + 3 aux commands + 1 filler word); 8 = ADCs; 2 = TTL in/out
end

function calculateDataBlockSizeInBytes(rhd::FPGA)
    rhd.numBytesPerBlock=2 * rhd.numWords
    nothing
end

function checkUsbHeader(usbBuffer,index)

    @inbounds x1 = convert(UInt64,usbBuffer[index])
    @inbounds x2 = convert(UInt64,usbBuffer[index+1])
    @inbounds x3 = convert(UInt64,usbBuffer[index+2])
    @inbounds x4 = convert(UInt64,usbBuffer[index+3])
    @inbounds x5 = convert(UInt64,usbBuffer[index+4])
    @inbounds x6 = convert(UInt64,usbBuffer[index+5])
    @inbounds x7 = convert(UInt64,usbBuffer[index+6])
    @inbounds x8 = convert(UInt64,usbBuffer[index+7])

    header = (x8 << 56) + (x7 << 48) + (x6 << 40) + (x5 << 32) + (x4 << 24) + (x3 << 16) + (x2 << 8) + (x1 << 0)

    return (header == RHD2000_HEADER_MAGIC_NUMBER)|(header==RHD2000_HEADER_MAGIC_NUMBER_OPEN_EPHYS)
end

function fillFromUsbBuffer!(fpgas::Array{FPGA,1},blockIndex::Int64,v,mytime)

    for fpga in fpgas
	fillFromUsbBuffer!(fpga,blockIndex,v,mytime)
    end
    nothing
end

function fillFromUsbBuffer!(fpga::FPGA,blockIndex::Int64,v,mytime)

    index = blockIndex * fpga.numBytesPerBlock + 1

    for t=1:SAMPLES_PER_DATA_BLOCK

	#Header
        if !checkUsbHeader(fpga.usbBuffer,index)
            if t==1 #first header missing, we're fucked. creep ahead and see what you find
                #Add data

                lag=0
                newindex=index

                for i=2:fpga.numBytesPerBlock
                    if checkUsbHeader(fpga.usbBuffer,i)
                        lag=i-index
                        newindex=i
                        break
                    end
                end

            else #something is messed up, probably in the last sample. start incrementing backward until header is found
                lag=0
                newindex=index
                for i=(index-1):-1:1
                    if checkUsbHeader(fpga.usbBuffer,i) #lag specifies number of bytes that are missing
                        lag=index-i
                        newindex=i
                        break
                    end
                end

                if lag>=(fpga.numBytesPerBlock/SAMPLES_PER_DATA_BLOCK) #somehow an extra byte popped up? will want to move forward instead
		lag=0
                newindex=index

                for i=(index+1):fpga.numBytesPerBlock
                    if checkUsbHeader(fpga.usbBuffer,i)
                        lag=i-index
                        newindex=i
                        break
                    end
                end

		end
            end

            #get extra bytes

            while (2*numWordsInFifo(fpga) < lag)
            end

            temp_array=zeros(UInt8,lag)

            ReadFromPipeOut(fpga,PipeOutData, convert(Clong, lag), temp_array)

	    if t==1 #moved forward, so bytes should be added to the end
	       count=1
	       for i=(fpga.numBytesPerBlock+1):(fpga.numBytesPerBlock+lag)
	       	   fpga.usbBuffer[i]=temp_array[count]
		   count+=1
	       end
	    else #moved backward, so skip everything in bad block, then start
	    	 count=1
	       for i=(fpga.numBytesPerBlock+1):(fpga.numBytesPerBlock+lag)
	       	   fpga.usbBuffer[i]=temp_array[count]
		   count+=1
	       end
	       t=t-1 #refill last block
	    end

            #start fresh
            index=newindex
        end

	index+=8
	mytime[t,fpga.id]=convertUsbTimeStamp(fpga.usbBuffer,index)
	index+=4

	#Auxiliary results
	index += (2*3*fpga.numDataStreams)

	#Amplifier
	for i=1:32
	    for j=1:fpga.numDataStreams
		@inbounds v[t,32*(j-1)+i+fpga.shift]=convertUsbWord(fpga.usbBuffer,index)
		index+=2
	    end
	end

	#skip filler word(s)
        if fpga.numDataStreams>0
	       index += 2
       end

	#ADCs
        for i=1:8
            @inbounds fpga.adc[t,i]=convertUsbWord(fpga.usbBuffer,index)
            index+=2
        end

	#TTL in
        @inbounds fpga.ttlin[t]=convertUsbWordu(fpga.usbBuffer,index)
        index += 2

        #TTL out
        @inbounds fpga.ttlout[t]=convertUsbWordu(fpga.usbBuffer,index)
	index += 2
    end

    nothing
end

function queueToFile(rhd::RHD2000,task::Task,fpga)

    if rhd.save.record_mode
        if rhd.save.save_full
            f=open(rhd.save.v, "a+")
            write(f,rhd.v)
            close(f)
        end
        if rhd.save.ttl_s
            f=open(rhd.save.ttl,"a+")
            write(f,fpga[1].ttlin)
            close(f)
        end
        if rhd.save.lfp_s
            f=open(rhd.save.lfp,"a+")
            write(f,rhd.lfps)
            close(f)
        end
        if rhd.save.adc_s
        end

        if rhd.save.ts_s
            writeTimeStamp(rhd)
        end

        save_task(task,rhd)
    end
    #Clear buffers
    @inbounds for i=1:size(rhd.buf,2)
        for j=1:rhd.nums[i]
            rhd.buf[j,i]=Spike()
        end
        rhd.nums[i]=0
    end
    nothing
end

function writeTimeStamp(rhd::RHD2000)

    #write spike times and cluster identity

    f=open(rhd.save.ts, "a+")

    for i=1:size(rhd.time,2)
        write(f,rhd.time[1,i])
    end

    @inbounds for i::UInt16=1:size(rhd.v,2)
        write(f,i) #channel number (UInt16)
        write(f,rhd.nums[i]) #number of spikes coming up (UInt16)
        for j=1:rhd.nums[i]
            write(f,rhd.buf[j,i].inds.start) #Index of start
            write(f,rhd.buf[j,i].inds.stop) #Index of stop
            write(f,rhd.buf[j,i].id) # cluster number (UInt8)
        end
    end

    close(f)

    nothing
end

function convertUsbTimeStamp(usbBuffer, index::Int64)

    @inbounds x1 = convert(UInt32,usbBuffer[index])
    @inbounds x2 = convert(UInt32,usbBuffer[index+1])
    @inbounds x3 = convert(UInt32,usbBuffer[index+2])
    @inbounds x4 = convert(UInt32,usbBuffer[index+3])

    convert(UInt32,((x4<<24) + (x3<<16) + (x2<<8) + (x1<<0)))
end

function convertUsbWord(usbBuffer, index::Int64)

    @inbounds x1 = convert(UInt16,usbBuffer[index])
    @inbounds x2 = convert(UInt16,usbBuffer[index+1])

    convert(Int16,signed((x2<<8)|x1)-typemax(Int16)) #is this right?
end

function convertUsbWordu(usbBuffer,index::Int64)

    @inbounds x1 = convert(UInt16,usbBuffer[index])
    @inbounds x2 = convert(UInt16,usbBuffer[index+1])

    (x2<<8)|x1
end

function SetWireInValue(rhd::FPGA, ep, val, mask = 0xffffffff)
    er=ccall(Libdl.dlsym(rhd.lib,:okFrontPanel_SetWireInValue),Cint,(Ptr{Void},Int,Culong,Culong),rhd.board,ep, val, mask)
end

function UpdateWireIns(rhd::FPGA)
    ccall(Libdl.dlsym(rhd.lib,:okFrontPanel_UpdateWireIns),Void,(Ptr{Void},),rhd.board)
    nothing
end

function UpdateWireOuts(rhd::FPGA)
    ccall(Libdl.dlsym(rhd.lib,:okFrontPanel_UpdateWireOuts),Void,(Ptr{Void},),rhd.board)
    nothing
end

function ActivateTriggerIn(rhd::FPGA,epAddr::UInt8,bit::Int)
    er=ccall(Libdl.dlsym(rhd.lib,:okFrontPanel_ActivateTriggerIn),Cint,(Ptr{Void},Int32,Int32),rhd.board,epAddr,bit)
end

function GetWireOutValue(rhd::FPGA,epAddr::UInt8)
    value = ccall(Libdl.dlsym(rhd.lib,:okFrontPanel_GetWireOutValue),Culong,(Ptr{Void},Int32),rhd.board,epAddr)
end

function ReadFromPipeOut(rhd::FPGA,epAddr::UInt8, length, data)
    ccall(Libdl.dlsym(rhd.lib,:okFrontPanel_ReadFromPipeOut),Clong,(Ptr{Void},Int32,Clong,Ptr{UInt8}),rhd.board,epAddr,length,data)
end

function ReadFromBlockPipeOut(fpga::FPGA,epAddr::UInt8,length,data)
ccall(Libdl.dlsym(fpga.lib,:okFrontPanel_ReadFromBlockPipeOut),Clong,(Ptr{Void},Int32,Int32,Clong,Ptr{UInt8}),fpga.board,epAddr,USB3_BLOCK_SIZE,length,data)
end

function ReadUsbBuffer(fpga::FPGA)
    ReadFromPipeOut(fpga,PipeOutData, convert(Clong, fpga.numBytesPerBlock), fpga.usbBuffer)
    nothing
end

ReadUsbBuffer(fpgas::Array{FPGA,1})=map(ReadUsbBuffer,fpgas)

function determine_delay(fpga::FPGA,port)

    setMaxTimeStep(fpga,SAMPLES_PER_DATA_BLOCK)
    setContinuousRunMode(fpga,false)
    selectAuxCommandBank(fpga,port,"AuxCmd3",0)

    output_delay=falses(16)

    for delay=0:15

        setCableDelay(fpga,port,delay)

	flushBoard(fpga)

        runBoard(fpga)

        while isRunning(fpga)
        end

	if fpga.usb3
	    SetWireInValue(fpga,WireInResetRun, 1 << 16, 1 << 16)
	    UpdateWireIns(fpga)
	    ReadFromBlockPipeOut(fpga,PipeOutData,2*convert(Clong,fpga.numWords),fpga.usbBuffer)
	    SetWireInValue(fpga,WireInResetRun, 0 << 16, 1 << 16);
	    UpdateWireIns(fpga)
	else
	    ReadFromPipeOut(fpga,PipeOutData, 2*convert(Clong, fpga.numWords * 1), fpga.usbBuffer)
	end
        index=1
        output=zeros(UInt16,60,fpga.numDataStreams)
        for t=1:60

            index+=12

            for j=1:3
                for i=1:fpga.numDataStreams
                    if j==3
                        output[t,i]=convertUsbWordu(fpga.usbBuffer,index)
                    end
                    index+=2
                end
            end

            #Amplifier
	    for i=1:32
	        for j=1:fpga.numDataStreams
		    index+=2
	        end
	    end

	    #skip 36 filler word
        if fpga.numDataStreams>0
	       index += 2
       end

	    #ADCs
            for i=1:8
                index+=2
            end

	    #TTL
	    index += 4
        end

        if check_delay_output(fpga,port,output)
            output_delay[delay+1]=true
        end
    end

    if all(.!output_delay)
        println("No delay setting produces optimum results")
	setCableLengthFeet(fpga,port, 6.0)
    else
        setCableDelay(fpga,port,find(output_delay.==true)[1]-1)
        println("Optimum delay on ", port, " is ", find(output_delay.==true)[1]-1)
        println("Approx ", approxCableLengthFeet(fpga,find(output_delay.==true)[1]-1), " feet")
    end

    nothing
end

function check_port_streams(fpga::FPGA,port)

    if port=="PortA"
        streams=sum((fpga.amps.==0).|(fpga.amps.==1).|(fpga.amps.==8).|(fpga.amps.==9))
    elseif port=="PortB"
        streams=sum((fpga.amps.==2).|(fpga.amps.==3).|(fpga.amps.==10).|(fpga.amps.==11))
    elseif port=="PortC"
        streams=sum((fpga.amps.==4).|(fpga.amps.==5).|(fpga.amps.==12).|(fpga.amps.==13))
    elseif port=="PortD"
        streams=sum((fpga.amps.==6).|(fpga.amps.==7).|(fpga.amps.==14).|(fpga.amps.==15))
    end

    streams
end

function check_delay_output(fpga::FPGA,port,output)

    data_stream_inds=find(fpga.dataStreamEnabled.==1)
    if port=="PortA"
        outinds=find((data_stream_inds.==1).|(data_stream_inds.==2).|(data_stream_inds.==9).|(data_stream_inds.==10))
    elseif port=="PortB"
        outinds=find((data_stream_inds.==3).|(data_stream_inds.==4).|(data_stream_inds.==11).|(data_stream_inds.==12))
    elseif port=="PortC"
        outinds=find((data_stream_inds.==5).|(data_stream_inds.==6).|(data_stream_inds.==13).|(data_stream_inds.==14))
    elseif port=="PortD"
        outinds=find((data_stream_inds.==7).|(data_stream_inds.==8).|(data_stream_inds.==15).|(data_stream_inds.==16))
    end

    hits=0
    for j in outinds
        hits+=output[33,j]==UInt16("I"[1])
        hits+=output[34,j]==UInt16("N"[1])
        hits+=output[35,j]==UInt16("T"[1])
        hits+=output[36,j]==UInt16("A"[1])
        hits+=output[37,j]==UInt16("N"[1])
        hits+=output[25,j]==UInt16("R"[1])
        hits+=output[26,j]==UInt16("H"[1])
        hits+=output[27,j]==UInt16("D"[1])
    end

    hits==length(outinds)*8
end

function Intan_GUI(myconfig_path=string(base_path,"Intan_config.jl"))

    include(myconfig_path)

end
