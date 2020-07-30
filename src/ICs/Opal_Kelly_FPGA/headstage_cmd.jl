

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
