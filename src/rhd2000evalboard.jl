
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
end

getlibrary(fpgas::Array{FPGA,1})=map(getlibrary,fpgas)

function getlibrary(fpga::FPGA)
    fpga.lib=Libdl.dlopen(intan_lib,Libdl.RTLD_NOW)
    fpga.board=ccall(Libdl.dlsym(fpga.lib,:okFrontPanel_Construct), Ptr{Void}, ())
    nothing
end

function init_board!(rhd::RHD2000)

    if rhd.debug.state==false
        map(open_board,rhd.fpga)
        map(uploadFpgaBitfile,rhd.fpga)
    else
        if typeof(rhd.fpga)==DArray{Intan.FPGA,1,Array{Intan.FPGA,1}}
            map(getlibrary,rhd.fpga)
        else
            for fpga in rhd.fpga
                getlibrary(fpga)
            end
        end
    end

    if typeof(rhd.fpga)==DArray{Intan.FPGA,1,Array{Intan.FPGA,1}}
        @sync for p in procs(rhd.fpga)
            @async remotecall_fetch((d,sr,db)->init_board_helper(localpart(d),sr,db),p,rhd.fpga,rhd.sr,rhd.debug.state)
        end
    else     
        init_board_helper(rhd.fpga,rhd.sr,rhd.debug.state)
    end

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
    stream=0
    for i in fpga.amps
        enableDataStream(fpga,stream,true)
        setDataSource(fpga,stream,i)
        stream+=1  
    end
    
    #Enable DAC
    enableDac(fpga,0,true)
    
    calculateDataBlockSizeInWords(fpga)
    calculateDataBlockSizeInBytes(fpga)
    
    setSampleRate(fpga,sr,mydebug)
    println("Sample Rate set at ",fpga.sampleRate, " on board ", fpga.id)
    
    #TODO this should be automatically selected based on what is plugged in where TODO
    setCableLengthFeet(fpga,"PortA", 3.0)
    
    ledArray=[1,0,0,0,0,0,0,0]
    setLedDisplay(fpga,ledArray)
    
    #Set up an RHD2000 register object using this sample rate to optimize MUX-related register settings.
    r=CreateRHD2000Registers(Float64(fpga.sampleRate))
    
    #Upload version with no ADC calibration to AuxCmd3 RAM Bank 0.
    commandList=createCommandListRegisterConfig(zeros(Int32,1),false,r)
    uploadCommandList(fpga,commandList, "AuxCmd3", 0)
    
    #Upload version with ADC calibration to AuxCmd3 RAM Bank 1.
    commandList=createCommandListRegisterConfig(zeros(Int32,1),true,r)
    uploadCommandList(fpga,commandList, "AuxCmd3", 1)
    
    selectAuxCommandLength(fpga,"AuxCmd3", 0, length(commandList) - 1)
    
    #Select RAM Bank 1 for AuxCmd3 initially, so the ADC is calibrated.
    selectAuxCommandBank(fpga,"PortA", "AuxCmd3", 1);
    
    setMaxTimeStep(fpga,SAMPLES_PER_DATA_BLOCK)
    setContinuousRunMode(fpga,false)
    
    if mydebug==false
        runBoard(fpga)
        while (isRunning(fpga))
        end
        flushBoard(fpga) 
    end
     
    selectAuxCommandBank(fpga,"PortA", "AuxCmd3", 0)   
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
    serial=Array(UInt8,11)
    ccall(Libdl.dlsym(fpga.lib,:okFrontPanel_GetDeviceListSerial), Int32, (Ptr{Void}, Int, Ptr{UInt8}), fpga.board, fpga.id,serial)
    serial[end]=0
    serialnumber=bytestring(pointer(serial))
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
    errorcode=ccall(Libdl.dlsym(rhd.lib,:okFrontPanel_ConfigureFPGA),Cint,(Ptr{Void},Ptr{UInt8}),rhd.board,bit)

    if errorcode==0
        println("FPGA configuration loaded.")
    else
        println("FPGA configuration failed.")
    end
      
    #Check if FrontPanel Support is enabled
    ccall(Libdl.dlsym(rhd.lib,:okFrontPanel_IsFrontPanelEnabled),Bool,(Ptr{Void},),rhd.board)

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

function initialize_board(fpgas::Array{FPGA,1})
    for fpga in fpgas
        initialize_board(fpga)
    end
    nothing
end

function initialize_board(rhd::FPGA,debug=false)
  
    resetBoard(rhd)
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

    for i=0:7; enableDac(rhd,i, false); end
    for i=0:7; selectDacDataStream(rhd,i, 0); end
    for i=0:7; selectDacDataChannel(rhd,i, 0); end

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

    nothing      
end

function resetBoard(rhd::FPGA)

    SetWireInValue(rhd,WireInResetRun, 0x01, 0x01)
    UpdateWireIns(rhd)
    SetWireInValue(rhd,WireInResetRun, 0x00, 0x01)
    UpdateWireIns(rhd)

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
    ActivateTriggerIn(rhd,TrigInDcmProg,0)
   
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
            ActivateTriggerIn(rhd,TrigInRamWrite,0)
        elseif auxCommandSlot == "AuxCmd2"
            ActivateTriggerIn(rhd,TrigInRamWrite,1)
        elseif auxCommandSlot == "AuxCmd3"
            ActivateTriggerIn(rhd,TrigInRamWrite,2)
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

    maxTimeStep=convert(UInt32, maxTimeStep)
    
    maxTimeStepLsb = maxTimeStep & 0x0000ffff
    maxTimeStepMsb = maxTimeStep & 0xffff0000

    SetWireInValue(rhd,WireInMaxTimeStepLsb,maxTimeStepLsb)
    SetWireInValue(rhd,WireInMaxTimeStepMsb,(maxTimeStepMsb >> 16))
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
    
    SetWireInValue(rhd,WireInMisoDelay, delay << bitShift, 0x000f << bitShift)
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

function selectDacDataStream(rhd::FPGA,dacChannel, stream)
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
    ActivateTriggerIn(rhd,TrigInDacThresh, dacChannel)

    #Set threshold polarity
    SetWireInValue(rhd,WireInMultiUse, (trigPolarity ? 1 : 0))
    UpdateWireIns(rhd)
    ActivateTriggerIn(rhd,TrigInDacThresh, dacChannel+8)

    nothing  
end

function enableExternalFastSettle(rhd::FPGA,enable)

    SetWireInValue(rhd,WireInMultiUse, (enable ? 1 : 0))
    UpdateWireIns(rhd)
    ActivateTriggerIn(rhd,TrigInExtFastSettle,0)

    nothing  
end

function setExternalFastSettleChannel(rhd::FPGA,channel)

    #error checking goes here

    SetWireInValue(rhd,WireInMultiUse,channel)
    UpdateWireIns(rhd)
    ActivateTriggerIn(rhd,TrigInExtFastSettle,1)

    nothing 
end

function enableExternalDigOut(rhd::FPGA,port, enable)

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

function setExternalDigOutChannel(rhd::FPGA,port, channel)

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

function setLedDisplay(rhd::FPGA,ledArray)

    ledOut=0
    for i=1:8
        if ledArray[i]>0
            ledOut += 1 << (i-1)
        end
    end

    SetWireInValue(rhd,WireInLedDisplay,ledOut)
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

    while (numWordsInFifo(rhd) >= (USB_BUFFER_SIZE/2))
        ReadFromPipeOut(rhd,PipeOutData, USB_BUFFER_SIZE, rhd.usbBuffer)
    end
    
    while (numWordsInFifo(rhd) > 0)
        ReadFromPipeOut(rhd,PipeOutData, (2 * numWordsInFifo(rhd)), rhd.usbBuffer)
    end

    nothing
end

function numWordsInFifo(rhd::FPGA)

    UpdateWireOuts(rhd)

    GetWireOutValue(rhd,WireOutNumWordsMsb)<<16+GetWireOutValue(rhd,WireOutNumWordsLsb)   
end

function compareNumWords(fpgas::Array{FPGA,1})
    out=false
    for fpga in fpgas
        out=out|compareNumWords(fpga)
    end
    out
end

compareNumWords(fpga::FPGA)=numWordsInFifo(fpga) < fpga.numWords

function compareNumWords(fpgas::DArray{Intan.FPGA,1,Array{Intan.FPGA,1}})

    out=false
    
    @sync for p in procs(fpgas)
        @async out=out|remotecall_fetch((d)->compareNumWords(localpart(d)),p,fpgas)
    end
    out                                
end

function readDataBlocks(rhd::RHD2000,numBlocks::Int64)

    if compareNumWords(rhd.fpga)
        return false
    end

    #=
    if (numBytesToRead > USB_BUFFER_SIZE)
        println("USB buffer size exceeded")
        return false
    end
    =#

    numRead=0

    if typeof(rhd.fpga)==DArray{Intan.FPGA,1,Array{Intan.FPGA,1}} #parallel

        @sync for p in procs(rhd.fpga)
            @async remotecall_wait((d)->ReadUsbBuffer(localpart(d)),p,rhd.fpga)
        end

    else
        numBytesToRead = rhd.fpga[1].numBytesPerBlock * numBlocks
        if length(rhd.fpga)>1
            for fpga in rhd.fpga
                ReadFromPipeOut(fpga,PipeOutData, convert(Clong, fpga.numBytesPerBlock * numBlocks), fpga.usbBuffer)
            end
            numRead=numBytesToRead
        else
            numRead=ReadFromPipeOut(rhd.fpga[1],PipeOutData, convert(Clong, numBytesToRead), rhd.fpga[1].usbBuffer)
        end  
    end

    for i=0:(numBlocks-1)

        #Move data from usbBuffer to v
        if typeof(rhd.fpga)==DArray{Intan.FPGA,1,Array{Intan.FPGA,1}} #parallel
            @sync for p in procs(rhd.fpga)
                @async remotecall_wait((d,ii,v)->fillFromUsbBuffer!(localpart(d),ii,v),p,rhd.fpga,i,rhd.v)
            end
        else
            fillFromUsbBuffer!(rhd.fpga,i,rhd.v)
        end

        for j=1:size(rhd.v,2)
            if rhd.refs[j]>0
                for k=1:size(rhd.v,1)
                    rhd.v[k,j]=rhd.v[k,j]-rhd.v[k,rhd.refs[j]]
                end
            end
        end

        #Filter
        #applyFilter(rhd)

        applySorting(rhd)       
    end
                            
    return true 
end

function applyFilter(rhd::RHD2000)

    for i=1:size(rhd.v,2)
        for j=1:SAMPLES_PER_DATA_BLOCK
            rhd.prev[j]=convert(Float64,rhd.v[j,i])
        end
        filt!(rhd.prev,rhd.filts[i],rhd.prev)
        for j=1:SAMPLES_PER_DATA_BLOCK
            rhd.v[j,i]=round(Int16,rhd.prev[j])
        end
    end
    nothing
end

function applySorting(rhd::RHD2000)

    if rhd.cal==0

        cal!(rhd.s,rhd.v,rhd.buf,rhd.nums,rhd.cal)
        rhd.cal=1
                      
    elseif rhd.cal<3

        cal!(rhd.s,rhd.v,rhd.buf,rhd.nums,rhd.cal)

        if rhd.reads>20
            rhd.cal=2
        end
        
    elseif rhd.cal==3
            
        onlinesort!(rhd.s,rhd.v,rhd.buf,rhd.nums)
    end

    rhd.reads+=1
    nothing 
end


function calculateDataBlockSizeInWords(rhd::FPGA)
    rhd.numWords = SAMPLES_PER_DATA_BLOCK * (4+2+(rhd.numDataStreams*36)+8+2)                         
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

    return (header == RHD2000_HEADER_MAGIC_NUMBER)
end

function fillFromUsbBuffer!(fpgas::Array{FPGA,1},blockIndex::Int64,v)

    for fpga in fpgas
    
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
            end
            
            #get extra bytes
            
            while (2*numWordsInFifo(fpga) < lag)
            end
            
            temp_array=zeros(UInt8,lag)
            
            ReadFromPipeOut(fpga,PipeOutData, convert(Clong, lag), temp_array)
            
            count=1
            for i=(fpga.numBytesPerBlock-lag+1):fpga.numBytesPerBlock
                fpga.usbBuffer[i]=temp_array[count]
                count+=1
            end
            
            #start fresh
            index=newindex
        end
	
	index+=8
	fpga.time[t]=convertUsbTimeStamp(fpga.usbBuffer,index)
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
        
	#skip 36 filler word
	index += (2*fpga.numDataStreams)
        
	#ADCs
        for i=1:8
            @inbounds fpga.adc[t,i]=convertUsbWordu(fpga.usbBuffer,index)     
            index+=2
        end
        
	#TTL in
        @inbounds fpga.ttlin[t]=convertUsbWordu(fpga.usbBuffer,index)
        index += 2
        
        #TTL out
        @inbounds fpga.ttlout[t]=convertUsbWordu(fpga.usbBuffer,index)
	index += 2	
    end

    end
    nothing
end

function queueToFile(rhd::RHD2000,sav::SaveAll)

    #write analog voltage traces
    f=open(rhd.save.v, "a+")

    write(f,rhd.v)
    close(f)

    writeTimeStamp(rhd)
    nothing
end

function queueToFile(rhd::RHD2000,sav::SaveWave)
    
    f=open(v_save_file,"a+")
    for i=1:size(rhd.v,2)
        for j=1:rhd.nums[i]
            if rhd.buf[j,i].inds[1]>0
                write(f,rhd.v[rhd.buf[j,i].inds,i])
            end
        end
    end
    close(f)
    
    writeTimeStamp(rhd)
    nothing
end

function queueToFile(rhd::RHD2000,sav::SaveNone)
    writeTimeStamp(rhd)
end

function writeTimeStamp(rhd::RHD2000)

    #write spike times and cluster identity

    f=open(rhd.save.ts, "a+")

    write(f,rhd.fpga[1].time[1])

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

    save_task(rhd.task,rhd)

    #Clear buffers
    @inbounds for i=1:size(rhd.buf,2)
        for j=1:rhd.nums[i]
            rhd.buf[j,i]=Spike()
        end
        rhd.nums[i]=0
    end
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

function ReadUsbBuffer(fpga::FPGA)
    ReadFromPipeOut(fpga,PipeOutData, convert(Clong, fpga.numBytesPerBlock), fpga.usbBuffer)
    nothing
end

ReadUsbBuffer(fpgas::Array{FPGA,1})=map(ReadUsbBuffer,fpgas)
