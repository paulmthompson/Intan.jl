


function SetWireInValue(rhd::FPGA, ep, val, mask = 0xffffffff)
    er=ccall(Libdl.dlsym(rhd.lib,:okFrontPanel_SetWireInValue),Cint,(Ptr{Nothing},Int,Culong,Culong),rhd.board,ep, val, mask)
end

function UpdateWireIns(rhd::FPGA)
    ccall(Libdl.dlsym(rhd.lib,:okFrontPanel_UpdateWireIns),Nothing,(Ptr{Nothing},),rhd.board)
    nothing
end

function UpdateWireOuts(rhd::FPGA)
    ccall(Libdl.dlsym(rhd.lib,:okFrontPanel_UpdateWireOuts),Nothing,(Ptr{Nothing},),rhd.board)
    nothing
end

function ActivateTriggerIn(rhd::FPGA,epAddr::UInt8,bit::Int)
    er=ccall(Libdl.dlsym(rhd.lib,:okFrontPanel_ActivateTriggerIn),Cint,(Ptr{Nothing},Int32,Int32),rhd.board,epAddr,bit)
end

function GetWireOutValue(rhd::FPGA,epAddr::UInt8)
    value = ccall(Libdl.dlsym(rhd.lib,:okFrontPanel_GetWireOutValue),Culong,(Ptr{Nothing},Int32),rhd.board,epAddr)
end

function ReadFromPipeOut(rhd::FPGA,epAddr::UInt8, length, data)
    ccall(Libdl.dlsym(rhd.lib,:okFrontPanel_ReadFromPipeOut),Clong,(Ptr{Nothing},Int32,Clong,Ptr{UInt8}),rhd.board,epAddr,length,data)
end

function ReadFromBlockPipeOut(fpga::FPGA,epAddr::UInt8,length,data)
ccall(Libdl.dlsym(fpga.lib,:okFrontPanel_ReadFromBlockPipeOut),Clong,(Ptr{Nothing},Int32,Int32,Clong,Ptr{UInt8}),fpga.board,epAddr,USB3_BLOCK_SIZE,length,data)
end

function ReadUsbBuffer(fpga::FPGA)
    ReadFromPipeOut(fpga,PipeOutData, convert(Clong, fpga.numBytesPerBlock), fpga.usbBuffer)
    nothing
end
