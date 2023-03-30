

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

function estimateCableLengthMeters(fpga,delay)

    tStep=1.0 / (2800.0 * fpga.sampleRate)
    cableVelocity = 0.555 * speedOfLight
    distance = cableVelocity * ((delay - 1.0) * tStep - (xilinxLvdsOutputDelay + rhd2000Delay + xilinxLvdsInputDelay + misoSettleTime))
    if distance <0.0
        distance = 0.0
    end
    distance / 2.0
end

function approxCableLengthFeet(fpga,delay)
    estimateCableLengthMeters(fpga,delay) * 3.2808
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

    SetWireInValue(rhd,WireInMisoDelay, delay << bitShift, 0x0000000f << bitShift)
    UpdateWireIns(rhd)

    nothing
end

function check_delay_output(fpga::FPGA,port,output)

    data_stream_inds=findall(dropdims(fpga.dataStreamEnabled,dims=1) .==1 ) #This is a 2D array, need to convert to 1D
    if port=="PortA"
        outinds=findall((data_stream_inds.==1).|(data_stream_inds.==2).|(data_stream_inds.==9).|(data_stream_inds.==10))
    elseif port=="PortB"
        outinds=findall((data_stream_inds.==3).|(data_stream_inds.==4).|(data_stream_inds.==11).|(data_stream_inds.==12))
    elseif port=="PortC"
        outinds=findall((data_stream_inds.==5).|(data_stream_inds.==6).|(data_stream_inds.==13).|(data_stream_inds.==14))
    elseif port=="PortD"
        outinds=findall((data_stream_inds.==7).|(data_stream_inds.==8).|(data_stream_inds.==15).|(data_stream_inds.==16))
    end

    hits=0
    for j in outinds
        hits += output[33,j] == UInt16("I"[1])
        hits += output[34,j]==UInt16("N"[1])
        hits += output[35,j]==UInt16("T"[1])
        hits += output[36,j]==UInt16("A"[1])
        hits+=output[37,j]==UInt16("N"[1])
        hits+=output[25,j]==UInt16("R"[1])
        hits+=output[26,j]==UInt16("H"[1])
        hits+=output[27,j]==UInt16("D"[1])
    end

    hits==length(outinds)*8
end


function determine_delay(fpga::FPGA,port)

    setMaxTimeStep(fpga,SAMPLES_PER_DATA_BLOCK)
    setContinuousRunMode(fpga,false)
    selectAuxCommandBank(fpga,port,"AuxCmd3",0)

    output_delay=falses(16)

    for delay=0:15

        setCableDelay(fpga,port,delay)

	flushBoard(fpga)

        runBoard(fpga)

        while isRunning(fpga)
        end

	if fpga.usb3
	    SetWireInValue(fpga,WireInResetRun, 1 << 16, 1 << 16)
	    UpdateWireIns(fpga)
	    ReadFromBlockPipeOut(fpga,PipeOutData,2*convert(Clong,fpga.numWords),fpga.usbBuffer)
	    SetWireInValue(fpga,WireInResetRun, 0 << 16, 1 << 16);
	    UpdateWireIns(fpga)
	else
	    ReadFromPipeOut(fpga,PipeOutData, 2*convert(Clong, fpga.numWords * 1), fpga.usbBuffer)
	end
        index=1
        output=zeros(UInt16,60,fpga.numDataStreams)
        for t=1:60

            index+=12

            for j=1:3
                for i=1:fpga.numDataStreams
                    if j==3
                        output[t,i]=convertUsbWordu(fpga.usbBuffer,index)
                    end
                    index+=2
                end
            end

            #Amplifier

	    for i=1:32
	        for j=1:fpga.numDataStreams
		    index+=2
	        end
	    end

	    #skip 36 filler word
        if fpga.numDataStreams>0
	       index += 2
       end

	    #ADCs
            for i=1:8
                index+=2
            end

	    #TTL
	    index += 4
        end

        if check_delay_output(fpga,port,output)
            output_delay[delay+1]=true
        end
    end

    if all(.!output_delay)
        println("No delay setting produces optimum results")
	    setCableLengthFeet(fpga,port, 6.0)
    else
        setCableDelay(fpga,port,findall(output_delay.==true)[1]-1)
        println("Optimum delay on ", port, " is ", findall(output_delay.==true)[1]-1)
        println("Approx ", approxCableLengthFeet(fpga,findall(output_delay.==true)[1]-1), " feet")
    end

    nothing
end
