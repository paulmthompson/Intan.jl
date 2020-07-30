
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
