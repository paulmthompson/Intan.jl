
module rhd2000evalboard

export open_board, uploadFpgaBitfile, initialize_board

const mylib="/home/nicolelislab/toolbox/DataAcq/libokFrontPanel.so"
const myfile="/home/nicolelislab/neural-analysis-toolbox/DataAcq/API/main.bit"

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
    selectAuxCommandBank("PortA","AuxCmd1", 0);
    selectAuxCommandBank("PortB", "AuxCmd1", 0);
    selectAuxCommandBank("PortC", "AuxCmd1", 0);
    selectAuxCommandBank("PortD", "AuxCmd1", 0);
    selectAuxCommandBank("PortA", "AuxCmd2", 0);
    selectAuxCommandBank("PortB", "AuxCmd2", 0);
    selectAuxCommandBank("PortC", "AuxCmd2", 0);
    selectAuxCommandBank("PortD", "AuxCmd2", 0);
    selectAuxCommandBank("PortA", "AuxCmd3", 0);
    selectAuxCommandBank("PortB", "AuxCmd3", 0);
    selectAuxCommandBank("PortC", "AuxCmd3", 0);
    selectAuxCommandBank("PortD", "AuxCmd3", 0);
    
    
       
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
        
    elseif commandslot=="AuxCmd2"
        
    elseif commandslot=="AuxCmd3"
        
    end

    ccall((:okFrontPanel_UpdateWireIns,mylib),Cint,(Ptr{Void},),x)
    
end


end
