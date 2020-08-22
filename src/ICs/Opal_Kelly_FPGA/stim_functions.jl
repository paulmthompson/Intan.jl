

#WireInGlobalSettleSelect =

function setGlobalSettlePolicy(fpga,settleWholeHeadstageA,settleWholeHeadstageB, settleWholeHeadstageC,
                                             settleWholeHeadstageD, settleAllHeadstages)


    value = (settleAllHeadstages ? 16 : 0) + (settleWholeHeadstageA ? 1 : 0) + (settleWholeHeadstageB ? 2 : 0) +
            (settleWholeHeadstageC ? 4 : 0) + (settleWholeHeadstageD ? 8 : 0);

    SetWireInValue(fpga,WireInGlobalSettleSelect, value, 0x001f);
    UpdateWireIns(fpga);
}
