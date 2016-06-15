// SoundGenerator.swift
// SynthInC
//
// Created by Brad Howes
// Copyright (c) 2016 Brad Howes. All rights reserved.

import Foundation
import AudioToolbox
import CoreAudio
import AVFoundation

/**
 Manages the audio components and instruments used to play the "In C" score. Holds a set of Instrument instances, each
 of which holds an AUSampler element that will play a unique track.
 */
final class AudioController  {
    let maxSamplerCount = Parameters.maxInstrumentCount
    private(set) var graph: AUGraph = nil
    private(set) var mixerUnit: AudioUnit = nil
    private(set) var mixerNode: AUNode = 0
    private(set) var musicPlayer: MusicPlayer = nil
    private(set) var musicSequence: MusicSequence = nil
    private(set) var sequenceLength: MusicTimeStamp = 0
    private(set) var activeInstruments: [Instrument] = []
    private var instruments: [Instrument] = []
    private var musicTrackMap: [Instrument:MusicTrack] = [:]

    /**
     Initialize instance. Creates the AudioUnit graph with a collection of AUSampler units and a multichannel mixer.
     Next, it generates a score for each sampler and initializes a MusicPlayer to play it.
     */
    init() {
        Parameters.dump()
        if setupGraph() && startGraph() {

            if !restoreSetup() { createSetup() }

            createPlayer()

            if !restoreMusicSequence() { createMusicSequence() }
        }
    }
}

// MARK: - AudioUnit Graph
extension AudioController {

    /**
     Create the AudioUnit graph, populate with AUSamplers from Instrument instances, and create a multichannel mixer for
     mixing the AUSampler outputs.
     
     - returns: true if successful, false otherwise
     */
    private func setupGraph() -> Bool {
        precondition(graph == nil)
        
        if CheckError("NewAUGraph", NewAUGraph(&graph)) {
            return false
        }
        
        // Create samplers
        //
        for _ in 0..<maxSamplerCount {
            let instrument = Instrument(audioController: self, index: instruments.count)
            if instrument.createSampler() {
                instruments.append(instrument)
            }
        }

        // Create mixer node for all samplers
        //
        mixerNode = 0
        var desc = AudioComponentDescription(componentType: OSType(kAudioUnitType_Mixer),
                                             componentSubType: OSType(kAudioUnitSubType_MultiChannelMixer),
                                             componentManufacturer: OSType(kAudioUnitManufacturer_Apple),
                                             componentFlags: 0, componentFlagsMask: 0)
        if CheckError("AUGraphAddNode(mixer)", AUGraphAddNode(graph, &desc, &mixerNode)) {
            return false
        }

        // Create final output node
        //
        var outputNode: AUNode = 0
        desc = AudioComponentDescription(componentType: OSType(kAudioUnitType_Output),
                                         componentSubType: OSType(kAudioUnitSubType_RemoteIO),
                                         componentManufacturer: OSType(kAudioUnitManufacturer_Apple),
                                         componentFlags: 0, componentFlagsMask: 0)
        if CheckError("AUGraphAddNode(output)", AUGraphAddNode(graph, &desc, &outputNode)) {
            return false
        }
        
        // Open graph now that we have all of the nodes. ** Must be done before any node wiring **
        //
        if CheckError("AUGraphOpen", AUGraphOpen(graph)) {
            return false
        }
        
        // Fetch the AudioUnit object for the mixer node
        //
        if CheckError("AUGraphNodeInfo(mixer)", AUGraphNodeInfo(graph, mixerNode, nil, &mixerUnit)) {
            return false
        }
        
        // Configure the max number of inputs to the mixer
        //
        var busCount = UInt32(instruments.count);
        if CheckError("AudioUnitSetProperty(mixer)", AudioUnitSetProperty(mixerUnit, kAudioUnitProperty_ElementCount,
            kAudioUnitScope_Input, 0, &busCount, UInt32(sizeofValue(busCount)))) {
            return false
        }
        
        // Set the sample rate for the mixer
        //
        if !setAudioUnitSampleRate(mixerUnit) {
            return false
        }
        
        // Wire the mixer output to the hardware (speaker, headphone, Bluetooth, etc.)
        //
        if CheckError("AUGraphConnectNodeInput", AUGraphConnectNodeInput(graph, mixerNode, 0, outputNode, 0)) {
            return false
        }
        
        // Wire the instrument samplers to the mixer. Success if all were wired without error
        //
        return (instruments.filter { !$0.wireSampler() }).isEmpty
    }

    /**
     Start the AudioUnit graph. This will allow audio to flow when MIDI events happen.
     
     - returns: true if successful
     */
    private func startGraph() -> Bool {
        precondition(instruments.count > 0)
        
        // Check if graph is already initialized
        //
        var isInitialized: DarwinBoolean = false
        if CheckError("AUGraphIsInitialized", AUGraphIsInitialized(graph, &isInitialized)) {
            return false
        }
        
        // Initialize it if not already
        //
        if isInitialized == false {
            if CheckError("AUGraphInitialize", AUGraphInitialize(graph)) {
                return false
            }
        }

        // Check if graph is already running
        //
        var isRunning: DarwinBoolean = false
        if CheckError("AUGraphIsRunning", AUGraphIsRunning(graph, &isRunning)) {
            return false
        }

        // Try to start the graph
        //
        if isRunning == false {
            print("-- starting AUGraph")
            if CheckError("AUGraphStart", AUGraphStart(graph)) {
                return false
            }
            print("-- AUGraph started")
        }
        else {
            print("-- AUGraph already running")
        }
        
        return true
    }

    /**
     Update the AudioUnit graph after changes are made to connections. Not currently used.
     
     - returns: true if successful
     */
    private func updateGraph() -> Bool {
        precondition(instruments.count > 0)
        var outIsUpdated = DarwinBoolean(false)
        if CheckError("AUGraphUpdate", AUGraphUpdate(graph, &outIsUpdated)) {
            return false
        }
        
        print("-- AUGraph updated: \(outIsUpdated)")
        return true
    }
    
    /**
     Stop the AudioUnit graph.
     
     - returns: true if successful
     */
    private func stopGraph() -> Bool {
        precondition(instruments.count > 0)
        var isRunning: DarwinBoolean = false
        if CheckError("AUGraphIsRunning", AUGraphIsRunning(graph, &isRunning)) {
            return false
        }
        
        if isRunning == true {
            print("-- stopping AUGraph")
            if CheckError("AUGraphStop", AUGraphStop(graph)) {
                return false
            }
            print("-- AUGraph stopped")
        }
        else {
            print("-- AUGraph already stopped")
        }
        
        return true
    }
}

// MARK: - Instrument Setup
extension AudioController {

    /**
     Create an initial set of active instruments.
     */
    private func createSetup() {
        precondition(activeInstruments.count == 0)
        print("-- creating setup")
        for index in 0..<min(8, instruments.count) {
            let instrument = instruments[index]
            instrument.setActiveDefaults()
            activeInstruments.append(instrument)
        }
    }

    /**
     Safe the current instrument configuration.
     */
    private func saveSetup() {
        print("-- saving setup")
        let configs: [NSData] = activeInstruments.map { $0.getSetup() }
        Parameters.setup = NSKeyedArchiver.archivedDataWithRootObject(configs)
    }

    /**
     Save one instrument's configuration.
     
     - parameter instrument: the Instrument instance to save
     - parameter data: the NSData describing the current configuration
     
     - returns: true if successful
     */
    func saveSetup(instrument: Instrument, data: NSData) -> Bool {
        print("-- saving instrument \(instrument.index)")
        guard let index = activeInstruments.indexOf(instrument) else { return false }
        guard let configData: NSData = Parameters.setup else { return false }
        guard var configs = NSKeyedUnarchiver.unarchiveObjectWithData(configData) as? [NSData] else { return false }
        configs[index] = data
        Parameters.setup = NSKeyedArchiver.archivedDataWithRootObject(configs)
        return true
    }

    /**
     Restore a saved configuration.
     
     - returns: true if successful
     */
    private func restoreSetup() -> Bool {
        print("-- restoring setup")
        activeInstruments.removeAll()
        guard let data: NSData = Parameters.setup else {
            print("** no NSData to unarchive")
            return false
        }
        
        guard let configs = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? [NSData] else {
            print("** invalid NSData format for config array")
            return false
        }

        configs.forEach {
            let instrument = instruments[activeInstruments.count]
            if !instrument.restoreSetup($0) { print("** failed to restore instrumen \(instrument.index)") }
            activeInstruments.append(instrument)
        }

        return true
    }
}

// MARK: - Music Sequence
extension AudioController {

    /**
     Create a new musical sequence to play.
     
     - returns: true if successful
     */
    func createMusicSequence() -> Bool {
        precondition(activeInstruments.count > 0)

        if musicSequence != nil { deleteMusicSequence() }
        guard !CheckError("NewMusicSequence", NewMusicSequence(&musicSequence)) else { return false }
        guard !CheckError("MusicSequenceSetAUGraph", MusicSequenceSetAUGraph(musicSequence, graph)) else { return false }

        // Generate MusicTrack objects for each instrument. Remember the longest track duration
        //
        musicTrackMap = [:]
        activeInstruments.forEach {
            let (musicTrack, beatClock) = $0.createMusicTrack(musicSequence)
            if musicTrack != nil {
                $0.assignToMusicTrack(musicTrack)
                musicTrackMap[$0] = musicTrack
                sequenceLength = max(beatClock, sequenceLength)
            }
        }

        saveMusicSequence()

        return updatePlayer()
    }

    /**
     Delete the existing music sequence.
     */
    private func deleteMusicSequence() {
        precondition(musicPlayer != nil)
        guard musicSequence != nil else { return }
        CheckError("MusicPlayer", MusicPlayerSetSequence(musicPlayer, nil))
        CheckError("DisposeMusicSequence", DisposeMusicSequence(musicSequence))
        musicSequence = nil
        sequenceLength = 0.0
    }

    /**
     Get the index of a MusicTrack in the current MusicSequence instance.
     
     - parameter musicTrack: the track to look for
     
     - returns: the index of the given track or -1 if not found
     */
    private func getTrackIndex(musicTrack: MusicTrack) -> Int {
        var trackIndex: UInt32 = 0
        return CheckError("MusicSequenceGetTrackIndex", MusicSequenceGetTrackIndex(musicSequence, musicTrack,
            &trackIndex)) ? -1 : Int(trackIndex)
    }

    /**
     Save the current MusicSequence instance.
     
     - returns: true if successful
     */
    private func saveMusicSequence() -> Bool {
        precondition(musicSequence != nil)
        print("-- saving music sequence")
        let data = NSMutableData()
        let encoder = NSKeyedArchiver(forWritingWithMutableData: data)

        var cfData: Unmanaged<CFData>?
        guard !CheckError("MusicSequenceFileCreateData", MusicSequenceFileCreateData(musicSequence, .MIDIType,
            .EraseFile, 480, &cfData)) else { return false }

        let sequenceData: NSData = cfData!.takeRetainedValue()
        encoder.encodeObject(sequenceData, forKey: "sequenceData")

        // Obtain an array with MIDI track indices for the active instruments
        //
        let trackMap: NSArray = activeInstruments.map { NSNumber.init(integer: getTrackIndex(musicTrackMap[$0]!)) }
        encoder.encodeObject(trackMap, forKey: "trackMap")
        encoder.finishEncoding()

        Parameters.sequence = data
        saveSetup()

        return true
    }

    /**
     Get the MusicTrack of the current MusicSequence instance at a given index.
     
     - parameter index: the index of the track to fetch
     
     - returns: MusicTrack instance if successful, nil otherwise
     */
    private func getIndTrack(index: Int) -> MusicTrack? {
        var musicTrack: MusicTrack = nil
        return CheckError("MusicSequenceGetIndTrack(\(index))", MusicSequenceGetIndTrack(musicSequence, UInt32(index),
            &musicTrack)) ? nil : musicTrack
    }

    /**
     Restore a saved MusicSequence and its tracks.

     - returns: true if successful
     */
    private func restoreMusicSequence() -> Bool {
        print("-- attempting to restore previous music sequence")

        guard let data = Parameters.sequence else {
            print("** no NSData for sequence")
            return false
        }

        deleteMusicSequence()

        let decoder = NSKeyedUnarchiver(forReadingWithData: data)
        guard let sequenceData = decoder.decodeObjectForKey("sequenceData") as? NSData else {
            print("** invalid NSData for sequence data")
            return false
        }

        guard !CheckError("NewMusicSequence", NewMusicSequence(&musicSequence)) else { return false }
        guard !CheckError("MusicSequenceSetAUGraph", MusicSequenceSetAUGraph(musicSequence, graph)) else { return false }
        guard !CheckError("MusicSequenceFileLoadData", MusicSequenceFileLoadData(musicSequence, sequenceData, .AnyType,
            .SMF_PreserveTracks)) else { return false }

        guard let objTrackIndices = decoder.decodeObjectForKey("trackMap") as? NSArray else {
            print("** invalid object for track map")
            return false
        }

        
        let trackIndices = objTrackIndices.map { getIndTrack(Int($0.integerValue)) }

        // Assign MusicTrack instances with the Instrument it was last assigned to
        //
        musicTrackMap = [:]
        zip(activeInstruments, trackIndices).forEach {
            (instrument, musicTrack) in
            instrument.assignToMusicTrack(musicTrack!)
            musicTrackMap[instrument] = musicTrack
        }

        return updatePlayer()
    }
}

// MARK: - Music Player
extension AudioController {

    /**
     Create a new MusicPlayer instance that will control the playback of MIDI data.
     
     - returns: true if successful
     */
    private func createPlayer() -> Bool {
        deletePlayer()
        if CheckError("NewMusicPlayer", NewMusicPlayer(&musicPlayer)) {
            return false
        }
        return true
    }

    /**
     Delete the current MusicPlayer instance
     */
    private func deletePlayer() {
        if musicPlayer != nil {
            if musicSequence != nil && isPlaying() { stop() }
            CheckError("DisposeMusicPlayer", DisposeMusicPlayer(musicPlayer))
            musicPlayer = nil
        }
    }
    
    /**
     Update the current MusicPlayer instance to reflect any changes to the current MusicSequence instance.
     
     - returns: true if successful
     */
    private func updatePlayer() -> Bool {
        precondition(musicSequence != nil)
        
        // Locate the longest track duration in the sequence
        //
        sequenceLength = (activeInstruments.maxElement { $0.trackDuration > $1.trackDuration })!.trackDuration
        print("sequenceLength: \(sequenceLength)")
        return !CheckError("MusicPlayerSetSequence", MusicPlayerSetSequence(musicPlayer, musicSequence)) &&
            !CheckError("MusicPlayerSetLength", MusicPlayerSetTime(musicPlayer, 0.0)) &&
            !CheckError("MusicPlayerPreroll", MusicPlayerPreroll(musicPlayer))
    }
}

// MARK: - Instrument Management
extension AudioController {
    
    /**
     Create a new active Instrument and a MusicTrack track for it to play.
     
     - parameter pos: where to put the new Instrument instance among the other active ones
     
     - returns: true if successful
     */
    func addInstrument(pos: Int) -> Bool {
        precondition(musicPlayer != nil && activeInstruments.count < instruments.count)

        let wasPlaying = isPlaying()
        if wasPlaying { stop() }

        let instrument = instruments[activeInstruments.count]
        instrument.setActiveDefaults()
        
        if pos < activeInstruments.count {
            instrument.patch = activeInstruments[pos].patch
        }

        let (musicTrack, beatClock) = instrument.createMusicTrack(musicSequence)
        if musicTrack == nil {
            instrument.enabled = false
            return false
        }

        instrument.assignToMusicTrack(musicTrack)
        musicTrackMap[instrument] = musicTrack
        activeInstruments.insert(instrument, atIndex: pos)
        sequenceLength = max(beatClock, sequenceLength)

        if wasPlaying { play() }

        saveSetup()
        saveMusicSequence()

        return true
    }

    /**
     Remove an active instrument, making it available in the future.
     
     - parameter pos: location of the Instrument in activeInstruments to remove
     
     - returns: true if successful
     */
    func removeInstrument(pos: Int) -> Bool {
        precondition(pos >= 0 && pos < activeInstruments.count)

        let wasPlaying = isPlaying()
        if wasPlaying { stop() }

        let instrument = activeInstruments.removeAtIndex(pos)
        instrument.assignToMusicTrack(nil)
        musicTrackMap[instrument] = nil
        sequenceLength = (activeInstruments.maxElement { $0.trackDuration > $1.trackDuration })!.trackDuration

        if wasPlaying { play() }

        saveSetup()
        saveMusicSequence()

        return true
    }
    
    /**
     Move an instrument from one position to another in activeInstruments array.
     
     - parameter fromPos: original postion
     - parameter toPos: new position
     */
    func reorderInstrument(fromPos fromPos: Int, toPos: Int) {
        print("reorder: \(fromPos)  \(toPos)")
        activeInstruments.insert(activeInstruments.removeAtIndex(fromPos), atIndex: toPos)
        saveSetup()
    }
}

// MARK: - Playback Control
extension AudioController {
    
    /**
     Obtain the MusicPlayer playing status.
     
     - returns: true if it is playing, false otherwise
     */
    func isPlaying() -> Bool {
        if musicPlayer == nil {
            return false
        }
        
        var playing: DarwinBoolean = false
        if CheckError("MusicPlayerIsPlaying", MusicPlayerIsPlaying(musicPlayer, &playing)) {
            return false
        }
        
        return Bool(playing)
    }
    
    /**
     Enumeration for the result of the playOrStop method.

     - Play: indication that the MusicPlayer is playing
     - Stop: indication that the MusicPlayer is **not** playing
     */
    enum PlayOrStop {
        case Play, Stop
    }

    /**
     Start an idle MusicPlayer or stop an active one
     
     - returns: PlayOrStop.Play if MusicPlayer is currently playing
     */
    func playOrStop() -> PlayOrStop {
        if isPlaying() {
            stop()
            return .Stop
        }
        else {
            return play() ? .Play : .Stop
        }
    }
    
    /**
     Start the MusicPlayer
     
     - returns: true if successful
     */
    func play() -> Bool {
        precondition(musicSequence != nil && musicPlayer != nil)
        print("-- starting MusicPlayer")
        if CheckError("MusicPlayerStart", MusicPlayerStart(musicPlayer)) {
            return false
        }
        print("-- started MusicPlayer")
        return true
    }
    
    /**
     Stop the MusicPlayer
     
     - returns: true if successful
     */
    func stop() -> Bool {
        precondition(musicSequence != nil && musicPlayer != nil)
        if !CheckError("MusicPlayerStop", MusicPlayerStop(musicPlayer)) {
            print("-- stopped MusicPlayer")
        }
        return true
    }
    
    /**
     Set the playback position of the MusicPlayer
     
     - parameter position: timestamp in "beats" to move to
     */
    func setPlaybackPosition(position: MusicTimeStamp) {
        precondition(musicPlayer != nil)
        print("-- playback position: \(position)")
        if MusicPlayerSetTime(musicPlayer, position) != 0 {
            print("*** failed to set playback position")
        }
    }

    /**
     Obtain the current playback position
     
     - returns: MusicPlayer playback location
     */
    func getPlaybackPosition() -> MusicTimeStamp {
        precondition(musicPlayer != nil)
        var position: MusicTimeStamp = 0
        if MusicPlayerGetTime(musicPlayer, &position) != 0 {
            print("*** failed to fetch position")
            return 0
        }

        return position
    }
}
