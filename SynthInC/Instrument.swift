//
//  Instrument.swift
//  SynthInC
//
//  Created by Brad Howes on 6/6/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation
import AVFoundation

final class Instrument: NSObject {
    let audioController: AudioController
    let index: Int

    fileprivate(set) var samplerNode: AUNode = 0
    fileprivate(set) var samplerUnit: AudioUnit? = nil

    // -- Entries below here are restorable --

    fileprivate(set) var sectionStarts: [MusicTimeStamp] = []

    var trackDuration: MusicTimeStamp { return sectionStarts[phrases.count] }
    var patch: Patch { didSet { applyPatch() } }
    var octave: Int = 0 { didSet { applyOctave() } }

    var volume: Float = 0.75 { didSet { applyVolume() } }
    var pan: Float = 0.0 { didSet { applyPan() } }
    var enabled: Bool = false { didSet { applyEnabled() } }
    var muted: Bool = false { didSet { applyEnabled() } }
    fileprivate var savedMuted: Bool = false
    var solo: Bool = false

    /**
     Initialize new instance.
     
     - parameter audioController: the AudioController instance that manages audio (our owner)
     - parameter index: unique ID in range of [0..N] where N is the maximum number of Instrument objects.
     */
    init(audioController: AudioController, index: Int) {
        self.audioController = audioController
        self.index = index
        self.patch = SoundFont.randomPatch()
        super.init()
    }
    
    /**
     Remove ourselves as an NSNotificationCenter observer since we are dying
     */
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func applyPatch() {
        guard samplerUnit != nil else { return }

        // Fetch the sound data from the sound font
        // FIXME: move to a SoundFont cache
        // FIXME: bank selection does not seem to work
        //
        var data = AUSamplerInstrumentData(fileURL: Unmanaged.passUnretained(patch.soundFont!.fileURL as CFURL),
                                           instrumentType: UInt8(kInstrumentType_SF2Preset),
                                           bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                                           bankLSB: UInt8(kAUSampler_DefaultBankLSB),
                                           presetID: UInt8(patch.patch))

        // Attempt to have the sampler use the sound font data
        //
        if CheckError("AudioUnitSetProperty(patch)", AudioUnitSetProperty(samplerUnit!,
            kAUSamplerProperty_LoadInstrument, kAudioUnitScope_Global, 0, &data, UInt32(MemoryLayout.size(ofValue: data)))) {

            // Try a "safe" patch
            //
            self.patch = RolandNicePiano.patches[0]
            return
        }

        let gain = patch.soundFont!.dbGain
        if CheckError("AudioUnitSetProperty(gain)", AudioUnitSetParameter(samplerUnit!, kAUSamplerParam_Gain,
            kAudioUnitScope_Global, 0, gain, 0)) {
            print("** failed to set gain")
        }
    }

    /**
     Apply the current octave setting to the sampler AudioUnit
     */
    fileprivate func applyOctave() {
        guard samplerUnit != nil else { return }
        let result: Float = Float(min(2, max(octave, -2))) * 12.0
        _ = CheckError("AudioUnitSetParameter(Tuning)", AudioUnitSetParameter(samplerUnit!,
                                                                              kAUSamplerParam_CoarseTuning,
                                                                              kAudioUnitScope_Global, 0, result, 0))
    }

    /**
     Apply the current volume setting to the mixer AudioUnit
     */
    fileprivate func applyVolume() {
        guard samplerUnit != nil else { return }
        _ = CheckError("AudioUnitSetParameter(Volume)", AudioUnitSetParameter(audioController.mixerUnit!,
                                                                              kMultiChannelMixerParam_Volume,
                                                                              kAudioUnitScope_Input, UInt32(index),
                                                                              volume, 0))
    }

    /**
     Apply the current pan setting to the mixer AudioUnit
     */
    fileprivate func applyPan() {
        guard samplerUnit != nil else { return }
        _ = CheckError("AudioUnitSetParameter(Pan)", AudioUnitSetParameter(audioController.mixerUnit!,
                                                                           kMultiChannelMixerParam_Pan,
                                                                           kAudioUnitScope_Input, UInt32(index), pan,
                                                                           0))
    }

    /**
     Apply the enabled setting to the mixer AudioUnit
     */
    fileprivate func applyEnabled() {
        guard samplerUnit != nil else { return }
        let result: Float = (enabled && !muted) ? 1.0 : 0.0
        _ = CheckError("AudioUnitSetParameter(Enable)", AudioUnitSetParameter(audioController.mixerUnit!,
                                                                              kMultiChannelMixerParam_Enable,
                                                                              kAudioUnitScope_Input, UInt32(index),
                                                                              result, 0))
    }

    /**
     Change notification for solo state of an instrument.
     
     - parameter instrument: the Instrument that is the solo instrument
     - parameter active: true if solo is active
     */
    func solo(_ instrument: Instrument, active: Bool) {
        if active {
            if self == instrument {
                print("-- solo instrument \(index)")
                savedMuted = muted
                muted = false
                solo = true
            }
            else {
                print("-- not solo instrument - muting \(index)")
                savedMuted = muted
                muted = true
            }
        }
        else {
            print("-- restoring \(index) \(savedMuted)")
            muted = savedMuted
            solo = false
        }
    }

    /**
     Get the phrase/section being played by the Instrument
     
     - parameter clock: the MusicPlayer timestamp
     
     - returns: the phrase number
     */
    func getSectionPlaying(_ clock: MusicTimeStamp) -> Int {
        for index in 0..<sectionStarts.count {
            if sectionStarts[index] >= clock {
                return index + 1
            }
        }
        
        return sectionStarts.count
    }

    /**
     Create a sampler AudioUnit to generate sounds for this instrument.
     
     - returns: true if successful
     */
    func createSampler() -> Bool {
        print("-- creating sampler \(index)")
        samplerNode = 0
        var desc = AudioComponentDescription(
            componentType: OSType(kAudioUnitType_MusicDevice),
            componentSubType: OSType(kAudioUnitSubType_Sampler),
            componentManufacturer: OSType(kAudioUnitManufacturer_Apple),
            componentFlags: 0, componentFlagsMask: 0)
        if CheckError("AUGraphAddNode(sampler)", AUGraphAddNode(audioController.graph!, &desc, &samplerNode)) {
            return false
        }
        
        return true
    }

    /**
     Connect the sampler to the app's multichannel mixer.
     
     - returns: true if successful
     */
    func wireSampler() -> Bool {
        precondition(samplerNode != 0 && audioController.mixerNode != 0)
        print("-- wiring sampler \(index)")

        // Get the AudioUnit associated with each sampler. We will need this later when we set the soundfont
        //
        samplerUnit = nil
        if CheckError("AUGraphNodeInfo(sampler)", AUGraphNodeInfo(audioController.graph!, samplerNode, nil,
            &samplerUnit)) {
            return false
        }
        
        // Set the sample rate to match the mixer
        //
        if !setAudioUnitSampleRate(samplerUnit!) {
            return false
        }
        
        // Connect the sampler output to a unique mixer input
        //
        if CheckError("AUGraphConnectNodeInput(sampler)", AUGraphConnectNodeInput(audioController.graph!, samplerNode,
            0, audioController.mixerNode, UInt32(index))) {
            return false
        }
        
        enabled = false

        return true
    }

    /**
     Set default parameter values for an active instrument.
     */
    func setActiveDefaults() {
        enabled = true
        muted = false
        octave = 0
        volume = 0.75
        pan = RandomUniform.sharedInstance.uniform(-1.0, upper: 1.0)
        patch = SoundFont.randomPatch()
    }

    /**
     Save the current instrument's configuration.
     */
    func saveSetup() {
        let data = getSetup()
        _ = audioController.saveSetup(self, data: data)
    }

    /**
     Obtain the instrument's configuration settings in an NSData object
     
     - returns: NSData containing archived configuration values
     */
    func getSetup() -> Data {
        let data = NSMutableData()
        let encoder = NSKeyedArchiver(forWritingWith: data)
        
        encoder.encode(patch.soundFont!.name, forKey: "soundFontName")
        encoder.encode(patch.name, forKey: "patchName")
        
        let tmp = sectionStarts.map { NSNumber.init(value: $0 as Double) }
        encoder.encode(tmp, forKey: "sectionStarts")

        encoder.encode(octave, forKey: "octave")
        encoder.encode(volume, forKey: "volume")
        encoder.encode(pan, forKey: "pan")
        encoder.encode(muted, forKey: "muted")
        encoder.finishEncoding()
        
        return data as Data
    }

    /**
     Restore instrument's configuration settings using values found in an NSData object
     
     - parameter data: archived configuration data
     
     - returns: true if successful
     */
    func restoreSetup(_ data: Data) -> Bool {
        precondition(samplerUnit != nil)

        let decoder = NSKeyedUnarchiver(forReadingWith: data)

        guard let soundFontName = decoder.decodeObject(forKey: "soundFontName") as? String else { return false }
        guard let patchName = decoder.decodeObject(forKey: "patchName") as? String else { return false }
        if let soundFont = SoundFont.library[soundFontName],
            let patch = soundFont.findPatch(patchName) {
            self.patch = patch
        }

        guard let objSectionStarts = decoder.decodeObject(forKey: "sectionStarts") as? NSArray else { return false }
        self.sectionStarts = objSectionStarts.map { Double(($0 as AnyObject).doubleValue) }
        print(self.sectionStarts)

        octave = decoder.decodeInteger(forKey: "octave")
        volume = decoder.decodeFloat(forKey: "volume")
        pan = decoder.decodeFloat(forKey: "pan")
        muted = decoder.decodeBool(forKey: "muted")

        return true
    }

    /**
     Create a new MusicTrack object for a MusicSequence and generate an "In C" performance.
     
     - parameter musicSequence: the MusicSequence object to add to
     
     - returns: 2-tuple containing the new MusicTrack and the duration of the new track. If error, returns (nil, -1)
     */
    func createMusicTrack(_ musicSequence: MusicSequence) -> (MusicTrack?, MusicTimeStamp) {
        print("-- creating music track for instrument \(index)")

        var trackCount: UInt32 = 0
        if CheckError("MusicSequenceGetTrackCount", MusicSequenceGetTrackCount(musicSequence, &trackCount)) {
            return (nil, -1.0)
        }

        var track: MusicTrack? = nil
        sectionStarts.removeAll()
        if CheckError("MusicSequenceNewTrack", MusicSequenceNewTrack(musicSequence, &track)) {
            return (nil, -1.0)
        }

        var beatClock = MusicTimeStamp(0.0)
        for phrase in phrases {
            sectionStarts.append(beatClock)
            let repVar = RandomUniform.sharedInstance.uniform(0.0, upper:Parameters.seqRepVar)
            let reps = max(1, Int((Parameters.seqRepNorm + repVar) / phrase.beats))
            for _ in 0..<reps {
                beatClock = phrase.addToTrack(track!, clock: beatClock)
            }
        }

        // Record the duration of this instrument's track
        //
        sectionStarts.append(beatClock)

        return (track!, beatClock)
    }

    /**
     Assign a MusicTrack to the instrument. A MusicTrack will drive the sampler, causing it to generate audio based 
     
     - parameter musicTrack: the MusicTrack to link to. May be nil.
     */
    func assignToMusicTrack(_ musicTrack: MusicTrack?) {
        print("-- assigning instrument \(index) to track \(musicTrack)")
        _ = CheckError("MusicTrackSetDestNode", MusicTrackSetDestNode(musicTrack!, samplerNode))
        if musicTrack != nil {
            applyOctave()
            applyPan()
            applyVolume()
            enabled = true
        }
        else {
            enabled = false
        }
    }
}
