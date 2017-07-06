
#=
These functions are needed for specific hardware implementations
=#

#=
Audio
=#

set_audio(fp::Array{FPGA,1},h::Gui_Handles,r::RHD2000)=set_audio_fpga(fp,h.spike,r.refs[h.spike])

function set_audio(fpga::DArray{FPGA,1,Array{FPGA,1}},han::Gui_Handles,rhd::RHD2000)

    remotecall_wait(((x,h,ii)->set_audio_fpga(localpart(x),h,ii)),2,fpga,han.spike,rhd.refs[han.spike])
    
end

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

#=
Bandwidth Adjustment
=#


change_bandwidth(fpgas::Array{FPGA,1},lower,upper,dsp_lower)=change_bandwidth_fpga(fpgas,lower,upper,dsp_lower)

change_bandwidth(fpgas::DArray{FPGA,1,Array{FPGA,1}},lower,upper,dsp_lower)=change_bandwidth_fpga(fpgas,lower,upper,dsp_lower)

function change_bandwidth_fpga(fpgas::Array,lower,upper,dsp_lower)

    for fpga in fpgas
        setLowerBandwidth(lower,fpga.r)
        setUpperBandwidth(upper,fpga.r)
        setDspCutoffFreq(dsp_lower,fpga.r)
        commandList=createCommandListRegisterConfig(zeros(Int32,1),true,fpga.r)
        uploadCommandList(fpga,commandList, "AuxCmd3", 1)
    end
    nothing
end

function change_bandwidth_fpga(fpgas::DArray,lower,upper,dsp_lower)

    @sync begin
        for p in procs(fpgas)
            @async remotecall_wait((ff)->change_bandwidth(localpart(ff),lower,upper,dsp_lower),p,fpgas)
        end
    end
    nothing
end

#=
Threshold
=#

function send_thres_to_ic(han::Gui_Handles,fpga::Array{FPGA,1})
    nothing
end

function send_thres_to_ic(han::Gui_Handles,fpga::DArray{FPGA,1,Array{FPGA,1}})
    nothing
end

#=
Select New Channel
=#

new_single_channel(han::Gui_Handles,rhd::RHD2000,s,fpga::Array{FPGA,1})=new_single_channel_fpga(han,rhd,s,fpga)
    
new_single_channel(han::Gui_Handles,rhd::RHD2000,s,fpga::DArray{FPGA,1,Array{FPGA,1}})=new_single_channel_fpga(han,rhd,s,fpga)

function new_single_channel_fpga(han::Gui_Handles,rhd::RHD2000,s,fpga)

    han.spike=han.chan_per_display*han.num16-han.chan_per_display+han.num
    
    clear_c2(han.sc.c2,han.spike)
    han.sc.ctx2=getgc(han.sc.c2)
    han.sc.ctx2s=copy(han.sc.ctx2)

    #Audio output
    set_audio(fpga,han,rhd)

    #Display Gain
    setproperty!(han.gainbox,:value,round(Int,han.scale[han.spike,1]*-1000))

    #Display Threshold
    get_thres(han,s)
    
    han.buf.ind=1
    han.buf.count=1

    #Get Cluster
    get_cluster(han,s)

    #Update treeview
    update_treeview(han)

    #update selected cluster
    select_unit(han)

    #Sort Button
    if han.sort_cb
        draw_templates(han)
    end

    han.spike_changed=false
    
    nothing
end
