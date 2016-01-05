#=
Constants
=#

#Constant parameters

#const lib = "$(Pkg.dir("Intan"))/lib/libokFrontPanel.so"
#const bit = "$(Pkg.dir("Intan"))/lib/main.bit"

const lib = "/home/nicolelislab/Intan.jl/lib/libokFrontPanel.so"
const bit = "/home/nicolelislab/Intan.jl/lib/main.bit"

const board = ccall((:okFrontPanel_Construct, lib), Ptr{Void}, ())

const USB_BUFFER_SIZE = 2400000
const RHYTHM_BOARD_ID = 500
const MAX_NUM_DATA_STREAMS = 8
const FIFO_CAPACITY_WORDS = 67108864
const SAMPLES_PER_DATA_BLOCK = 600

const WireInResetRun = 0x00
const WireInMaxTimeStepLsb = 0x01
const WireInMaxTimeStepMsb = 0x02
const WireInDataFreqPll = 0x03
const WireInMisoDelay = 0x04
const WireInCmdRamAddr = 0x05
const WireInCmdRamBank = 0x06
const WireInCmdRamData = 0x07
const WireInAuxCmdBank1 = 0x08
const WireInAuxCmdBank2 = 0x09
const WireInAuxCmdBank3 = 0x0a
const WireInAuxCmdLength1 = 0x0b
const WireInAuxCmdLength2 = 0x0c
const WireInAuxCmdLength3 = 0x0d
const WireInAuxCmdLoop1 = 0x0e
const WireInAuxCmdLoop2 = 0x0f
const WireInAuxCmdLoop3 = 0x10
const WireInLedDisplay = 0x11
const WireInDataStreamSel1234 = 0x12
const WireInDataStreamSel5678 = 0x13
const WireInDataStreamEn = 0x14
const WireInTtlOut = 0x15
const WireInDacSource1 = 0x16
const WireInDacSource2 = 0x17
const WireInDacSource3 = 0x18
const WireInDacSource4 = 0x19
const WireInDacSource5 = 0x1a
const WireInDacSource6 = 0x1b
const WireInDacSource7 = 0x1c
const WireInDacSource8 = 0x1d
const WireInDacManual = 0x1e
const WireInMultiUse = 0x1f

const TrigInDcmProg = 0x40
const TrigInSpiStart = 0x41
const TrigInRamWrite = 0x42
const TrigInDacThresh = 0x43
const TrigInDacHpf = 0x44
const TrigInExtFastSettle = 0x45
const TrigInExtDigOut = 0x46

const WireOutNumWordsLsb = 0x20
const WireOutNumWordsMsb = 0x21
const WireOutSpiRunning = 0x22
const WireOutTtlIn = 0x23
const WireOutDataClkLocked = 0x24
const WireOutBoardMode = 0x25
const WireOutBoardId = 0x3e
const WireOutBoardVersion = 0x3f

const PipeOutData = 0xa0

#For 32 channel amps
const PortA1 = 0
const PortA2 = 1
const PortB1 = 2
const PortB2 = 3
const PortC1 = 4
const PortC2 = 5
const PortD1 = 6
const PortD2 = 7

#For 64 channel amps
const PortA1Ddr = 8
const PortA2Ddr = 9
const PortB1Ddr = 10
const PortB2Ddr = 11
const PortC1Ddr = 12
const PortC2Ddr = 13
const PortD1Ddr = 14
const PortD2Ddr = 15
