// SoundGenerator.swift
// SynthInC
//
// Created by Brad Howes
// Copyright (c) 2016 Brad Howes. All rights reserved.

import Foundation
import AudioToolbox
import CoreAudio
import AVFoundation
import GameKit

// internal var audioController: AudioController = AudioController()

/**
 Manages the audio components and instruments used to play the "In C" score. Holds a set of Instrument instances, each
 of which holds an AUSampler element that will play a unique track.
 */
public final class AudioController  {
    public fileprivate(set) var graph: AUGraph? = nil
    public fileprivate(set) var mixerUnit: AudioUnit? = nil
    public fileprivate(set) var mixerNode: AUNode = 0
    public fileprivate(set) var ensemble: [Instrument] = []

    public init() {
    }

    deinit {
        print("*** AudioController.deinit")
    }

    // MARK: - AudioUnit Graph

    /**
     Create the AudioUnit graph, populate with AUSamplers from Instrument instances, and create a multichannel mixer for
     mixing the AUSampler outputs.
     
     - returns: true if successful, false otherwise
     */
    public func createEnsemble(ensembleSize: Int, instrumentDoneCallback: @escaping (Int) -> Void, finishedCallback: @escaping (Bool) -> Void) {
        ensemble.removeAll()
        let workItem = DispatchWorkItem() {
            if self.beginSetup() {
                for index in 0..<ensembleSize {
                    let patch = FavoritePatches[index % FavoritePatches.count]
                    if let instrument = Instrument(graph: self.graph!, patch: patch) {
                        self.ensemble.append(instrument)
                    }
                }
            }
            
            self.finishSetup(instrumentDoneCallback: instrumentDoneCallback, finishedCallback: finishedCallback)
        }

        DispatchQueue.global(qos: .utility).async(execute: workItem)
    }

    public func restoreEnsemble(data: Data, instrumentDoneCallback: @escaping (Int) -> Void, finishedCallback: @escaping (Bool) -> Void) {
        ensemble.removeAll()
        let workItem = DispatchWorkItem() {
            if self.beginSetup() {
                let decoder = NSKeyedUnarchiver(forReadingWith: data)
                if let configs = decoder.decodeObject(forKey: "configs") as? [Data] {
                    for config in configs {
                        if let instrument = Instrument(graph: self.graph!, settings: config) {
                            self.ensemble.append(instrument)
                        }
                    }
                }
            }

            self.finishSetup(instrumentDoneCallback: instrumentDoneCallback, finishedCallback: finishedCallback)
        }

        DispatchQueue.global(qos: .utility).async(execute: workItem)
    }
    
    fileprivate func disposeGraph() -> Bool {
        guard let graph = self.graph else { return true }
        return stopGraph() && !IsAudioError("AUGraphClose", AUGraphClose(graph)) && !IsAudioError("DisposeAUGraph", DisposeAUGraph(graph))
    }
    
    fileprivate func beginSetup() -> Bool {
        return disposeGraph() && !IsAudioError("NewAUGraph", NewAUGraph(&graph))
    }

    fileprivate func finishSetup(instrumentDoneCallback: @escaping (Int) -> Void, finishedCallback: @escaping (Bool) -> Void) {

        var result = false
        defer { finishedCallback(result) }

        // Create mixer node for all samplers
        //
        mixerNode = 0
        var desc = AudioComponentDescription(componentType: OSType(kAudioUnitType_Mixer),
                                             componentSubType: OSType(kAudioUnitSubType_MultiChannelMixer),
                                             componentManufacturer: OSType(kAudioUnitManufacturer_Apple),
                                             componentFlags: 0, componentFlagsMask: 0)
        if IsAudioError("AUGraphAddNode(mixer)", AUGraphAddNode(graph!, &desc, &mixerNode)) {
            return;
        }

        // Create final output node
        //
        var outputNode: AUNode = 0
        desc = AudioComponentDescription(componentType: OSType(kAudioUnitType_Output),
                                         componentSubType: OSType(kAudioUnitSubType_RemoteIO),
                                         componentManufacturer: OSType(kAudioUnitManufacturer_Apple),
                                         componentFlags: 0, componentFlagsMask: 0)
        if IsAudioError("AUGraphAddNode(output)", AUGraphAddNode(graph!, &desc, &outputNode)) {
            return;
        }
        
        // Open graph now that we have all of the nodes. ** Must be done before any node wiring **
        //
        if IsAudioError("AUGraphOpen", AUGraphOpen(graph!)) {
            return;
        }
        
        // Fetch the AudioUnit object for the mixer node
        //
        if IsAudioError("AUGraphNodeInfo(mixer)", AUGraphNodeInfo(graph!, mixerNode, nil, &mixerUnit)) {
            return;
        }
        
        // Configure the max number of inputs to the mixer
        //
        var busCount = UInt32(ensemble.count);
        if IsAudioError("AudioUnitSetProperty(mixer)", AudioUnitSetProperty(mixerUnit!, kAudioUnitProperty_ElementCount,
            kAudioUnitScope_Input, 0, &busCount, UInt32(MemoryLayout.size(ofValue: busCount)))) {
            return;
        }
        
        // Set the sample rate for the mixer
        //
        if !setAudioUnitSampleRate(mixerUnit!) {
            return;
        }
        
        // Wire the mixer output to the hardware (speaker, headphone, Bluetooth, etc.)
        //
        if IsAudioError("AUGraphConnectNodeInput", AUGraphConnectNodeInput(graph!, mixerNode, 0, outputNode, 0)) {
            return;
        }
        
        // Wire the instrument samplers to the mixer. Success if all were wired without error
        //
        for index in 0..<ensemble.count {
            let instrument = ensemble[index]
            if !instrument.wireSampler(index: index, graph: graph!, mixerNode: mixerNode, mixerUnit: mixerUnit!) {
                return;
            }
        }

        guard startGraph() else { return }
        
        // It would be nice if we could configure instruments in parallel, but it appears that that is not
        // supported in AU.
        //
        ensemble.forEach { instrument in
            instrument.configureSampler(callback: instrumentDoneCallback)
        }
        
        result = true
    }

    /**
     Start the AudioUnit graph. This will allow audio to flow when MIDI events happen.
     
     - returns: true if successful
     */
    fileprivate func startGraph() -> Bool {
        guard let graph = self.graph else { return false }
        
        // Check if graph is already initialized
        //
        var isInitialized: DarwinBoolean = false
        if IsAudioError("AUGraphIsInitialized", AUGraphIsInitialized(graph, &isInitialized)) {
            return false
        }
        
        guard !isInitialized.boolValue else { return true }

        // Initialize it if not already
        //
        if IsAudioError("AUGraphInitialize", AUGraphInitialize(graph)) {
            return false
        }

        // Check if graph is already running
        //
        var isRunning: DarwinBoolean = false
        if IsAudioError("AUGraphIsRunning", AUGraphIsRunning(graph, &isRunning)) {
            return false
        }

        guard !isRunning.boolValue else { return true }

        print("-- starting AUGraph")
        if IsAudioError("AUGraphStart", AUGraphStart(graph)) {
            return false
        }
        print("-- AUGraph started")
        
        return true
    }

    /**
     Stop the AudioUnit graph.
     
     - returns: true if successful
     */
    fileprivate func stopGraph() -> Bool {
        guard let graph = self.graph else { return false }

        var isRunning: DarwinBoolean = false
        if IsAudioError("AUGraphIsRunning", AUGraphIsRunning(graph, &isRunning)) {
            return false
        }

        guard isRunning.boolValue else { return true }

        print("-- stopping AUGraph")
        if IsAudioError("AUGraphStop", AUGraphStop(graph)) {
            return false
        }
        print("-- AUGraph stopped")
        
        return true
    }

    /**
     Save the current instrument configuration.
     */
    public func encodeEnsemble() -> Data {
        print("-- saving setup")
        let data = NSMutableData()
        let encoder = NSKeyedArchiver(forWritingWith: data)
        let configs = ensemble.map { $0.encodeConfiguration() }
        encoder.encode(configs, forKey: "configs")
        encoder.finishEncoding()

        return data as Data
    }

    /**
     Save one instrument's configuration.
     
     - parameter instrument: the Instrument instance to save
     - parameter data: the NSData describing the current configuration
     
     - returns: true if successful
     */
//    public func updateSetup(_ instrument: Instrument, data: Data) -> Bool {
//        print("-- saving instrument \(instrument.index)")
//        guard let index = activeInstruments.index(of: instrument) else { return false }
//        guard let configData: Data = Parameters.setup as Data? else { return false }
//        guard var configs = NSKeyedUnarchiver.unarchiveObject(with: configData) as? [Data] else { return false }
//        configs[index] = data
//        Parameters.setup = NSKeyedArchiver.archivedData(withRootObject: configs)
//        return true
//    }

//    /**
//     Restore a saved configuration.
//     
//     - returns: true if successful
//     */
//    fileprivate func restoreSetup() -> Bool {
//        print("-- restoring setup")
//        activeInstruments.removeAll()
//        guard let data: Data = Parameters.setup as Data? else {
//            print("** no NSData to unarchive")
//            return false
//        }
//        
//        guard let configs = NSKeyedUnarchiver.unarchiveObject(with: data) as? [Data] else {
//            print("** invalid NSData format for config array")
//            return false
//        }
//
//        configs.forEach {
//            let instrument = instruments[activeInstruments.count]
//            if !instrument.restoreSetup($0) { print("** failed to restore instrumen \(instrument.index)") }
//            activeInstruments.append(instrument)
//        }
//
//        return true
//    }

}
