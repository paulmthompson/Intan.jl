//----------------------------------------------------------------------------------
// main.cpp
//
// Intan Technoloies RHD2000 Rhythm Interface API
// Version 1.2 (23 September 2013)
//
// Copyright (c) 2013 Intan Technologies LLC
//
// This software is provided 'as-is', without any express or implied warranty.
// In no event will the authors be held liable for any damages arising from the
// use of this software.
//
// Permission is granted to anyone to use this software for any applications that
// use Intan Technologies integrated circuits, and to alter it and redistribute it
// freely.
//
// See http://www.intantech.com for documentation and product information.
//----------------------------------------------------------------------------------

// #include <QtCore> // used for Qt applications
#include <iostream>
#include <fstream>
#include <vector>
#include <queue>
#include <time.h>

using namespace std;

#include "rhd2000evalboard.h"
#include "rhd2000registers.h"
#include "rhd2000datablock.h"
#include "okFrontPanelDLL.h"

int main(int argc, char *argv[])
{
    // QCoreApplication a(argc, argv); // used for Qt console applications

    Rhd2000EvalBoard *evalBoard = new Rhd2000EvalBoard;

    // Open Opal Kelly XEM6010 board.
    evalBoard->open();

    // Load Rhythm FPGA configuration bitfile (provided by Intan Technologies).
    string bitfilename;
    bitfilename = "main.bit";  // Place main.bit in the executable directory, or add a complete path to file.
    evalBoard->uploadFpgaBitfile(bitfilename);

    // Initialize board.
    evalBoard->initialize();
    evalBoard->setDataSource(0, Rhd2000EvalBoard::PortA1);

    // Select per-channel amplifier sampling rate.
    evalBoard->setSampleRate(Rhd2000EvalBoard::SampleRate20000Hz);

    // Now that we have set our sampling rate, we can set the MISO sampling delay
    // which is dependent on the sample rate.  We assume a 3-foot cable.
    evalBoard->setCableLengthFeet(Rhd2000EvalBoard::PortA, 3.0);

    // Let's turn one LED on to indicate that the program is running.
    int ledArray[8] = {1, 0, 0, 0, 0, 0, 0, 0};
    evalBoard->setLedDisplay(ledArray);

    // Set up an RHD2000 register object using this sample rate to optimize MUX-related
    // register settings.
    Rhd2000Registers *chipRegisters;
    chipRegisters = new Rhd2000Registers(evalBoard->getSampleRate());

    // Create command lists to be uploaded to auxiliary command slots.
    int commandSequenceLength;
    vector<int> commandList;

    // First, let's create a command list for the AuxCmd1 slot.  This command
    // sequence will create a 1 kHz, full-scale sine wave for impedance testing.
    commandSequenceLength = chipRegisters->createCommandListZcheckDac(commandList, 1000.0, 128.0); // 1000.0, 128.0
    evalBoard->uploadCommandList(commandList, Rhd2000EvalBoard::AuxCmd1, 0);
    evalBoard->selectAuxCommandLength(Rhd2000EvalBoard::AuxCmd1, 0, commandSequenceLength - 1);
    evalBoard->selectAuxCommandBank(Rhd2000EvalBoard::PortA, Rhd2000EvalBoard::AuxCmd1, 0);
    // evalBoard->printCommandList(commandList); // optionally, print command list

    // Next, we'll create a command list for the AuxCmd2 slot.  This command sequence
    // will sample the temperature sensor and other auxiliary ADC inputs.
    commandSequenceLength = chipRegisters->createCommandListTempSensor(commandList);
    evalBoard->uploadCommandList(commandList, Rhd2000EvalBoard::AuxCmd2, 0);
    evalBoard->selectAuxCommandLength(Rhd2000EvalBoard::AuxCmd2, 0, commandSequenceLength - 1);
    evalBoard->selectAuxCommandBank(Rhd2000EvalBoard::PortA, Rhd2000EvalBoard::AuxCmd2, 0);
    // evalBoard->printCommandList(commandList); // optionally, print command list

    // For the AuxCmd3 slot, we will create two command sequences.  Both sequences
    // will configure and read back the RHD2000 chip registers, but one sequence will
    // also run ADC calibration.

    // Before generating register configuration command sequences, set amplifier
    // bandwidth paramters.

    double dspCutoffFreq;
    dspCutoffFreq = chipRegisters->setDspCutoffFreq(10.0);
    cout << "Actual DSP cutoff frequency: " << dspCutoffFreq << " Hz" << endl;

    chipRegisters->setLowerBandwidth(1.0);
    chipRegisters->setUpperBandwidth(7500.0);

    commandSequenceLength = chipRegisters->createCommandListRegisterConfig(commandList, false);
    // Upload version with no ADC calibration to AuxCmd3 RAM Bank 0.
    evalBoard->uploadCommandList(commandList, Rhd2000EvalBoard::AuxCmd3, 0);

    chipRegisters->createCommandListRegisterConfig(commandList, true);
    // Upload version with ADC calibration to AuxCmd3 RAM Bank 1.
    evalBoard->uploadCommandList(commandList, Rhd2000EvalBoard::AuxCmd3, 1);

    evalBoard->selectAuxCommandLength(Rhd2000EvalBoard::AuxCmd3, 0, commandSequenceLength - 1);
    // Select RAM Bank 1 for AuxCmd3 initially, so the ADC is calibrated.
    evalBoard->selectAuxCommandBank(Rhd2000EvalBoard::PortA, Rhd2000EvalBoard::AuxCmd3, 1);
    // evalBoard->printCommandList(commandList); // optionally, print command list

    // Since our longest command sequence is 60 commands, let’s just run the SPI
    // interface for 60 samples.
    evalBoard->setMaxTimeStep(60);
    evalBoard->setContinuousRunMode(false);

    cout << "Number of 16-bit words in FIFO: " << evalBoard->numWordsInFifo() << endl;

    // Start SPI interface.
    evalBoard->run();

    // Wait for the 60-sample run to complete.
    while (evalBoard->isRunning()) { }

    cout << "Number of 16-bit words in FIFO: " << evalBoard->numWordsInFifo() << endl;

    // Read the resulting single data block from the USB interface.
    Rhd2000DataBlock *dataBlock = new Rhd2000DataBlock(evalBoard->getNumEnabledDataStreams());
    evalBoard->readDataBlock(dataBlock);

    // Display register contents from data stream 0.
    dataBlock->print(0);

    cout << "Number of 16-bit words in FIFO: " << evalBoard->numWordsInFifo() << endl;

    // Now that ADC calibration has been performed, we switch to the command sequence
    // that does not execute ADC calibration.
    evalBoard->selectAuxCommandBank(Rhd2000EvalBoard::PortA, Rhd2000EvalBoard::AuxCmd3, 0);


    // Grab current time and date for inclusion in filename
    char timeDateBuf[80];
    time_t now = time(0);
    struct tm tstruct;
    tstruct = *localtime(&now);

    // Construct filename
    string fileName;
    fileName = "C:\\";  // add your desired path here
    fileName += "test_";
    strftime(timeDateBuf, sizeof(timeDateBuf), "%y%m%d", &tstruct);
    fileName += timeDateBuf;
    fileName += "_";
    strftime(timeDateBuf, sizeof(timeDateBuf), "%H%M%S", &tstruct);
    fileName += timeDateBuf;
    fileName += ".dat";

    cout << endl << "Save filename:" << endl << "  " << fileName << endl << endl;

    // Let's save one second of data to a binary file on disk.
    ofstream saveOut;
    saveOut.open(fileName, ios::binary | ios::out);

    queue<Rhd2000DataBlock> dataQueue;

    // Run for one second.
    evalBoard->setMaxTimeStep(20000);
    cout << "Reading one second of RHD2000 data..." << endl;
    evalBoard->run();

    bool usbDataRead;
    do {
        usbDataRead = evalBoard->readDataBlocks(1, dataQueue);
        if (dataQueue.size() >= 50) {
            evalBoard->queueToFile(dataQueue, saveOut);
        }
    } while (usbDataRead || evalBoard->isRunning());

    evalBoard->queueToFile(dataQueue, saveOut);

    evalBoard->flush();

    saveOut.close();

    cout << "Done!" << endl << endl;

    // Optionally, set board to run continuously so we can observe SPI waveforms.
    // evalBoard->setContinuousRunMode(true);
    // evalBoard->run();

    // Turn off LED.
    ledArray[0] = 0;
    evalBoard->setLedDisplay(ledArray);

    // return a.exec();  // used for Qt applications
}

