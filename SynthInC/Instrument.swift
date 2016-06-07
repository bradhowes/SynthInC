//
//  Instrument.swift
//  SynthInC
//
//  Created by Brad Howes on 6/6/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation
import AVFoundation

let kSoloInstrumentNotificationKey = "SoloInstrument"
let kTrackDurationIndex = phrases.count

final class Instrument: NSObject {
    let audioController: AudioController
    let index: Int

    private(set) var samplerNode: AUNode = 0
    private(set) var samplerUnit: AudioUnit = nil

    // Entries below here are restorable

    private(set) var sectionStarts: [MusicTimeStamp] = []

    var trackDuration: MusicTimeStamp {
        precondition(sectionStarts.count == phrases.count + 1)
        return sectionStarts[kTrackDurationIndex]
    }

    var patch: Patch {
        didSet {
            precondition(patch.soundFont != nil)
            applyPatch()
        }
    }

    var octave: Int = 0 {
        didSet { applyOctave() }
    }

    private var soloSavedVolume: Float = 0.0
    var volume: Float = 1.0 {
        didSet { applyVolume() }
    }
    
    var pan: Float = 0.0 {
        didSet { applyPan() }
    }
    
    private var registeredForSolo = false

    var enabled: Bool = false {
        didSet { applyEnabled() }
    }

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
        if registeredForSolo {
            NSNotificationCenter.defaultCenter().removeObserver(self)
            registeredForSolo = false
        }
    }
    
    private func applyPatch() {
        if samplerUnit == nil { return }

        // Fetch the sound data from the sound font
        // FIXME: move to a SoundFont cache
        // FIXME: bank selection does not seem to work
        //
        var data = AUSamplerInstrumentData(fileURL: Unmanaged.passUnretained(patch.soundFont!.fileURL),
                                           instrumentType: UInt8(kInstrumentType_SF2Preset),
                                           bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                                           bankLSB: UInt8(kAUSampler_DefaultBankLSB),
                                           presetID: UInt8(patch.patch))
        
        // Attempt to have the sampler use the sound font data
        //
        CheckError("AudioUnitSetProperty", AudioUnitSetProperty(samplerUnit,
            AudioUnitPropertyID(kAUSamplerProperty_LoadInstrument), AudioUnitScope(kAudioUnitScope_Global), 0,
            &data, UInt32(sizeofValue(data))))
    }

    private func applyOctave() {
        if samplerUnit == nil { return }
        let result: Float = Float(min(2, max(octave, -2))) * 12.0
        CheckError("AudioUnitSetParameter(Tuning)", AudioUnitSetParameter(samplerUnit,
            kAUSamplerParam_CoarseTuning, kAudioUnitScope_Global, 0, result, 0))
    }

    private func applyVolume() {
        if samplerUnit == nil { return }
        CheckError("AudioUnitSetParameter(Volume)", AudioUnitSetParameter(audioController.mixerUnit,
            kMultiChannelMixerParam_Volume, kAudioUnitScope_Input, UInt32(index), volume, 0))
    }

    private func applyPan() {
        if samplerUnit == nil { return }
        CheckError("AudioUnitSetParameter(Pan)", AudioUnitSetParameter(audioController.mixerUnit,
            kMultiChannelMixerParam_Pan, kAudioUnitScope_Input, UInt32(index), pan, 0))
    }

    private func applyEnabled() {
        if samplerUnit == nil { return }
        let result: Float = enabled ? 1.0 : 0.0
        CheckError("AudioUnitSetParameter(Enable)", AudioUnitSetParameter(audioController.mixerUnit,
            kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, UInt32(index), result, 0))
        if enabled {
            registerForSoloNotifications()
        }
        else {
            unregisterForSoloNotifications()
        }
    }

    private func registerForSoloNotifications() {
        if enabled && !registeredForSolo {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(solo(_:)),
                                                             name: kSoloInstrumentNotificationKey, object: nil)
            registeredForSolo = true
        }
    }
    
    private func unregisterForSoloNotifications() {
        if registeredForSolo {
            NSNotificationCenter.defaultCenter().removeObserver(self)
            registeredForSolo = false
        }
    }
    
    /**
     Update our sound volume temporarily in response to a `solo` request. If the requesting object is ourselves, then
     max our own volume. Otherwise, mute requesting objects.
     
     - parameter notification: holds a `userInfo` map which should also contain the `Instrument` asking for solo
     treatment
     */
    func solo(notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }
        if let instrument = userInfo["instrument"] as? Instrument {
            if self == instrument {
                
                // For the solo instrument, we do not want to overwrite any volume changes that may happen while it is
                // in solo mode.
                //
                soloSavedVolume = 0.0
            }
            else if volume > 0.0 {
                soloSavedVolume = volume
                volume = 0.0
            }
        }
        else {
            
            // If zero, this instrument was the one being soloed OR it had a normal volume of zereo. In either case
            // we don't need to do a change.
            //
            if soloSavedVolume != 0.0 {
                volume = soloSavedVolume
            }
        }
    }
    
    /**
     Get the phrase/section being played by the Instrument
     
     - parameter clock: the MusicPlayer timestamp
     
     - returns: the phrase number
     */
    func getSectionPlaying(clock: MusicTimeStamp) -> Int {
        return sectionStarts.reduce(0) { (count, start) -> Int in count + (start > clock ? 0 : 1) }
    }
    
    func createSampler() -> Bool {
        samplerNode = 0
        var desc = AudioComponentDescription(
            componentType: OSType(kAudioUnitType_MusicDevice),
            componentSubType: OSType(kAudioUnitSubType_Sampler),
            componentManufacturer: OSType(kAudioUnitManufacturer_Apple),
            componentFlags: 0, componentFlagsMask: 0)
        if CheckError("AUGraphAddNode(sampler)", AUGraphAddNode(audioController.graph, &desc, &samplerNode)) {
            return false
        }
        
        return true
    }
    
    func wireSampler() -> Bool {
        precondition(samplerNode != 0 && audioController.mixerNode != 0)
        
        // Get the AudioUnit associated with each sampler. We will need this later when we set the soundfont
        //
        samplerUnit = nil
        if CheckError("AUGraphNodeInfo(sampler)", AUGraphNodeInfo(audioController.graph, samplerNode, nil,
            &samplerUnit)) {
            return false
        }
        
        // Set the sample rate to match the mixer
        //
        if !setAudioUnitSampleRate(samplerUnit) {
            return false
        }
        
        // Connect the sampler output to a unique mixer input
        //
        if CheckError("AUGraphConnectNodeInput(sampler)", AUGraphConnectNodeInput(audioController.graph, samplerNode,
            0, audioController.mixerNode, UInt32(index))) {
            return false
        }
        
        return true
    }

    func setActiveDefaults() {
        enabled = true
        octave = 0
        volume = 0.75
        pan = RandomUniform.sharedInstance.uniform(-1.0, upper: 1.0)
        patch = SoundFont.randomPatch()
    }

    func saveSetup() {
        let data = getSetup()
        audioController.saveSetup(self, data: data)
    }

    func getSetup() -> NSData {
        let data = NSMutableData()
        let encoder = NSKeyedArchiver(forWritingWithMutableData: data)
        
        encoder.encodeObject(patch.soundFont!.name, forKey: "soundFontName")
        encoder.encodeObject(patch.name, forKey: "patchName")
        
        let tmp: NSArray = sectionStarts.map { NSNumber.init(double: $0) }
        encoder.encodeObject(tmp, forKey: "sectionStarts")
        
        encoder.encodeInteger(octave, forKey: "octave")
        encoder.encodeFloat(volume, forKey: "volume")
        encoder.encodeFloat(pan, forKey: "pan")
        encoder.encodeBool(enabled, forKey: "enabled")
        encoder.finishEncoding()
        
        return data
    }

    func restoreSetup(data: NSData) -> Bool {
        precondition(samplerUnit != nil)

        let decoder = NSKeyedUnarchiver(forReadingWithData: data)

        guard let soundFontName = decoder.decodeObjectForKey("soundFontName") as? String else { return false }
        guard let patchName = decoder.decodeObjectForKey("patchName") as? String else { return false }
        if let soundFont = SoundFont.library[soundFontName],
            let patch = soundFont.findPatch(patchName) {
            self.patch = patch
        }

        guard let objSectionStarts = decoder.decodeObjectForKey("sectionStarts") as? NSArray else { return false }
        self.sectionStarts = objSectionStarts.map { Double($0.doubleValue) }
        print(self.sectionStarts)

        octave = decoder.decodeIntegerForKey("octave")
        volume = decoder.decodeFloatForKey("volume")
        pan = decoder.decodeFloatForKey("pan")
        enabled = decoder.decodeBoolForKey("enabled")

        return true
    }

    func createMusicTrack(musicSequence: MusicSequence) -> (MusicTrack, MusicTimeStamp) {

        var trackCount: UInt32 = 0
        if CheckError("MusicSequenceGetTrackCount", MusicSequenceGetTrackCount(musicSequence, &trackCount)) {
            return (nil, -1.0)
        }

        var track: MusicTrack = nil
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
                beatClock = phrase.addToTrack(track, clock: beatClock)
            }
        }

        // Record the duration of this instrument's track
        //
        sectionStarts.append(beatClock)

        return (track, beatClock)
    }

    func assignToMusicTrack(musicTrack: MusicTrack) {
        print("\(index) -> \(musicTrack)")
        CheckError("MusicTrackSetDestNode", MusicTrackSetDestNode(musicTrack, samplerNode))
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
