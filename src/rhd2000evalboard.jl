
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
    fpga.board=ccall(Libdl.dlsym(fpga.lib,:okFrontPanel_Construct), Ptr{Nothing}, ())
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

    if EMG
        setLowerBandwidth(2.0, fpga.r)
        setUpperBandwidth(1000.0, fpga.r)
        setDspCutoffFreq(10.0, fpga.r)
    end
    #Upload version with no ADC calibration to AuxCmd3 RAM Bank 0.
    commandList=createCommandListRegisterConfig(zeros(Int32,1),false,fpga.r)
    uploadCommandList(fpga,commandList, "AuxCmd3", 0)
    selectAuxCommandLength(fpga,"AuxCmd3", 0, length(commandList) - 1)

    #Upload version with ADC calibration to AuxCmd3 RAM Bank 1.
    commandList=createCommandListRegisterConfig(zeros(Int32,1),true,fpga.r)
    uploadCommandList(fpga,commandList, "AuxCmd3", 1)
    selectAuxCommandLength(fpga,"AuxCmd3", 1, length(commandList) - 1)

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
    fpga.board=ccall(Libdl.dlsym(fpga.lib,:okFrontPanel_Construct), Ptr{Nothing}, ())

    println("Scanning USB for Opal Kelly devices...")
    nDevices=ccall(Libdl.dlsym(fpga.lib,:okFrontPanel_GetDeviceCount), Int, (Ptr{Nothing},), fpga.board)
    println("Found ", nDevices, " Opal Kelly device(s)")

    #Get Serial Number
    serial=Array{UInt8}(undef,11)

    ccall(Libdl.dlsym(fpga.lib,:okFrontPanel_GetDeviceListSerial), Int32, (Ptr{Nothing}, Int, Ptr{UInt8}), fpga.board, fpga.id,serial)
    serial[end]=0
    serialnumber=unsafe_string(pointer(serial))
    println("Serial number of device 0 is ", serialnumber)

    #Open by serial
    if (ccall(Libdl.dlsym(fpga.lib,:okFrontPanel_OpenBySerial), Cint, (Ptr{Nothing},Ptr{UInt8}),fpga.board,serialnumber)!=0)
        println("Device could not be opened. Is one connected?")
        return -2
    end

    #configure on-board PLL
    ccall(Libdl.dlsym(fpga.lib,:okFrontPanel_LoadDefaultPLLConfiguration), Cint, (Ptr{Nothing},),fpga.board)

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
            errorcode=ccall(Libdl.dlsym(rhd.lib,:okFrontPanel_ConfigureFPGA),Cint,(Ptr{Nothing},Ptr{UInt8}),rhd.board,usb3bit_open_ephys)
        else
            errorcode=ccall(Libdl.dlsym(rhd.lib,:okFrontPanel_ConfigureFPGA),Cint,(Ptr{Nothing},Ptr{UInt8}),rhd.board,usb3bit)
        end
    else
        errorcode=ccall(Libdl.dlsym(rhd.lib,:okFrontPanel_ConfigureFPGA),Cint,(Ptr{Nothing},Ptr{UInt8}),rhd.board,bit)
    end
    if errorcode==0
        println("FPGA configuration loaded.")
    else
        println("FPGA configuration failed.")
    end


    #Check if FrontPanel Support is enabled
    myenable = ccall(Libdl.dlsym(rhd.lib,:okFrontPanel_IsFrontPanelEnabled),Bool,(Ptr{Nothing},),rhd.board)

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

    #clearTtlOut(rhd)

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

    setTtlMode(rhd,falses(8))

    #Loop through digital output sequencers
    for i=1:16
        rhd.d[i].channel=i
        update_digital_output(rhd,rhd.d[i])
    end

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

    #The ADC on the headstage can handle 1.05Mhz sampling, which is equal to 
    #35 channels (32 + 3 aux) at 30 kHz. However, the ADCs on Open Ephys and 
    #Intan board should be able to go up to 100 Khz.
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
    elseif newSampleRate==40000
        M=56
        D=25
    elseif newSampleRate==50000
        M=14
        D=5
    elseif newSampleRate==100000
        M=28
        D=5
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
            if (OPEN_EPHYS)
                try
                    rhd.v[:,1] = myfpga[1].adc[:,2] .- 2556 #open ephys special
                catch
                    for jj=1:size(rhd.v,1)
                        if abs(myfpga[1].adc[jj,2] - 2556)>typemax(Int16)
                        else
                            rhd.v[jj,1] = myfpga[1].adc[jj,2] - 2556
                        end
                    end
                end
            else
                try
                    rhd.v[:,1] = myfpga[1].adc[:,2]
                catch
                    for jj=1:size(rhd.v,1)
                        if abs(myfpga[1].adc[jj,2])>typemax(Int16)
                            rhd.v[jj,1] = typemax(Int16) * sign(myfpga[1].adc[jj,2])
                        else
                            rhd.v[jj,1] = myfpga[1].adc[jj,2]
                        end
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


    rhd.numWords = SAMPLES_PER_DATA_BLOCK * (4+2+(rhd.numDataStreams*35) + (rhd.numDataStreams % 4) + 8+2)

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
	      index += 2 * (fpga.numDataStreams % 4) #For USB3
          #index += 2 * fpga.numDataStreams
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
            #TTL in
            f=open(rhd.save.ttl,"a+")
            write(f,fpga[1].ttlin)
            close(f)

            #TTL out
            f=open(rhd.save.ttl_out,"a+")
            write(f,fpga[1].ttlout)
            close(f)
        end
        if rhd.save.lfp_s
            f=open(rhd.save.lfp,"a+")
            write(f,rhd.lfps)
            close(f)
        end
        if rhd.save.adc_s
            f=open(rhd.save.adc,"a+")
            write(f,fpga[1].adc)
            close(f)
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

ReadUsbBuffer(fpgas::Array{FPGA,1})=map(ReadUsbBuffer,fpgas)

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

function Intan_GUI(myconfig_path=string(base_path,"Intan_config.jl"))

    include(myconfig_path)

end
