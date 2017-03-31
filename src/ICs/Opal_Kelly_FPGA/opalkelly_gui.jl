
#New channel stuff
# set audio

function set_audio_fpga(fpga::Array,ii,refs)

    selectDacDataStream(fpga[1],0,div(ii-1,32))
    selectDacDataChannel(fpga[1],0,rem(ii-1,32))

    if refs>0
        enableDac(fpga[1],1,true)
        selectDacDataStream(fpga[1],1,div(refs-1,32))
        selectDacDataChannel(fpga[1],1,rem(refs-1,32))
    else
        enableDac(fpga[1],1,false)
    end
    nothing
end

set_audio(fp::Array{FPGA,1},h::Gui_Handles,r::RHD2000)=set_audio_fpga(fp,h.spike,r.refs[h.spike])

function set_audio(fpga::DArray{FPGA,1,Array{FPGA,1}},han::Gui_Handles,rhd::RHD2000)

    remotecall_wait(((x,h,ii)->set_audio_fpga(localpart(x),h,ii)),2,fpga,han.spike,rhd.refs[han.spike])
    
end
