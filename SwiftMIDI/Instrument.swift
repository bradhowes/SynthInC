//
//  Instrument.swift
//  SynthInC
//
//  Created by Brad Howes on 6/6/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation
import AVFoundation
import GameKit

/**
 Representation of a specific instrument in a performance. Each instrument has a SoundFont patch that
 defines the instrument's sound. There are also volume, panning parameters that will affect the sound
 the instrument generates.
 */
public final class Instrument: NSObject {
  var index: Int = -1
  fileprivate(set) var samplerNode: AUNode = 0
  fileprivate(set) var samplerUnit: AudioUnit!
  fileprivate(set) var mixerUnit: AudioUnit!
  fileprivate var soloMutedState: Bool = false
  public fileprivate(set) var ready: Bool = false

  /// The current SoundFont patch being used by the instrument
  public var patch: Patch { didSet { if (oldValue !== patch) { applyPatch() } } }
  /// The current octave the instrument plays in (0 being the default)
  public var octave: Int = 0 { didSet { if (oldValue != octave) { applyOctave() } } }
  /// The current volume the instrument plays at (0.75 being the default)
  public var volume: Float = 0.75 { didSet { if (oldValue != volume) { applyVolume() } } }
  /// The current stereo pan value, where -1 means all left channel, +1 means all right channel, and 0 is in the middle
  public var pan: Float = 0.0 { didSet { if (oldValue != pan) { applyPan() } } }
  /// If true, the instrument is muted and not generating any output audio
  public var muted: Bool = false { didSet { if (oldValue != muted) { applyMuted() } } }
  /// If true, this instrument is the only one playing. All others will be muted.
  public var solo: Bool = false

  /**
   Initialize new instance.

   - parameter graph: the AUGraph we belong to
   - parameter patch: the SoundFont patch to use for sound generating
   */
  init?(graph: AUGraph, patch: Patch) {
    self.patch = patch
    super.init()
    guard createSampler(graph: graph) else { return nil }
  }

  /**
   Initialize new instance from a saved configuration.

   - parameter graph: the AUGraph we belong to
   - parameter settings: configuration settings for the instrument.
   */
  init?(graph: AUGraph, settings: Data) {
    let decoder = NSKeyedUnarchiver(forReadingWith: settings)
    guard let soundFontName = decoder.decodeObject(forKey: "soundFontName") as? String else { return nil }
    guard let patchName = decoder.decodeObject(forKey: "patchName") as? String else { return nil }

    guard let soundFont = SoundFont.library[soundFontName] else { return nil }
    guard let patch = soundFont.findPatch(patchName) else { return nil }

    self.patch = patch
    super.init()

    self.octave = decoder.decodeInteger(forKey: "octave")
    self.volume = decoder.decodeFloat(forKey: "volume")
    self.pan = decoder.decodeFloat(forKey: "pan")
    self.muted = decoder.decodeBool(forKey: "muted")

    guard createSampler(graph: graph) else { return nil }
  }

  /**
   Remove ourselves as an NSNotificationCenter observer since we are dying
   */
  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  /**
   Create a sampler AudioUnit to generate sounds for this instrument.

   - returns: true if successful
   */
  fileprivate func createSampler(graph: AUGraph) -> Bool {
    print("-- creating sampler")
    precondition(samplerNode == 0)
    var desc = AudioComponentDescription(
      componentType: OSType(kAudioUnitType_MusicDevice),
      componentSubType: OSType(kAudioUnitSubType_Sampler),
      componentManufacturer: OSType(kAudioUnitManufacturer_Apple),
      componentFlags: 0, componentFlagsMask: 0)
    return !IsAudioError("AUGraphAddNode(sampler)", AUGraphAddNode(graph, &desc, &samplerNode))
  }

  /**
   Connect the sampler to the app's multichannel mixer.

   - returns: true if successful
   */
  public func wireSampler(index: Int, graph: AUGraph, mixerNode: AUNode, mixerUnit: AudioUnit) -> Bool {
    print("-- wiring sampler \(index)")

    self.index = index
    self.mixerUnit = mixerUnit
    self.samplerUnit = nil

    var tmp: AudioUnit?
    if IsAudioError("AUGraphNodeInfo(sampler)", AUGraphNodeInfo(graph, samplerNode, nil, &tmp)) {
      return false
    }

    self.samplerUnit = tmp!

    // Set the sample rate to match the mixer
    //
    guard setAudioUnitSampleRate(samplerUnit!) else { return false }

    // Connect the sampler output to a unique mixer input
    //
    if IsAudioError("AUGraphConnectNodeInput(sampler)", AUGraphConnectNodeInput(graph, samplerNode, 0, mixerNode, UInt32(index))) {
      return false
    }

    return true
  }

  public func configureSampler(callback: @escaping (Int)->Void) {
    ready = true
    applyOctave()
    applyVolume()
    applyPan()
    applyMuted()
    applyPatch()
    DispatchQueue.global(qos: .utility).async { callback(self.index) }
  }

  fileprivate func applyPatch() {
    precondition(samplerUnit != nil);
    guard ready else { return }

    // Fetch the sound data from the sound font
    // FIXME: move to a SoundFont cache
    // FIXME: bank selection does not seem to work
    //
    let bankMSB = UInt8(kAUSampler_DefaultMelodicBankMSB)
    let bankLSB = UInt8(kAUSampler_DefaultBankLSB)
    let presetID = UInt8(patch.patch)
    print("-- applyPatch \(bankMSB) \(bankLSB) \(presetID)")

    var data = AUSamplerInstrumentData(fileURL: Unmanaged.passUnretained(patch.soundFont.fileURL as CFURL),
                                       instrumentType: UInt8(kInstrumentType_SF2Preset),
                                       bankMSB: bankMSB,
                                       bankLSB: bankLSB,
                                       presetID: presetID)

    // Attempt to have the sampler use the sound font data
    //
    if IsAudioError("AudioUnitSetProperty(patch)", AudioUnitSetProperty(samplerUnit,
                                                                        kAUSamplerProperty_LoadInstrument, kAudioUnitScope_Global, 0, &data, UInt32(MemoryLayout.size(ofValue: data)))) {
      print("** failed to use patch")

      // Try a "safe" patch
      //
      // self.patch = RolandNicePiano.patches[0]
      // applyPatch()
      return
    }

    let gain = patch.soundFont!.dbGain
    _ = IsAudioError("AudioUnitSetProperty(gain)",
                     AudioUnitSetParameter(samplerUnit, kAUSamplerParam_Gain, kAudioUnitScope_Global, 0, gain, 0))
  }

  /**
   Apply the current octave setting to the sampler AudioUnit
   */
  fileprivate func applyOctave() {
    precondition(samplerUnit != nil)
    guard ready else { return }
    let result: Float = Float(min(2, max(octave, -2))) * 12.0
    _ = IsAudioError("AudioUnitSetParameter(Tuning)",
                     AudioUnitSetParameter(samplerUnit, kAUSamplerParam_CoarseTuning, kAudioUnitScope_Global, 0, result, 0))
  }

  /**
   Apply the current volume setting to the mixer AudioUnit
   */
  fileprivate func applyVolume() {
    precondition(mixerUnit != nil)
    guard ready else { return }
    _ = IsAudioError("AudioUnitSetParameter(Volume)",
                     AudioUnitSetParameter(mixerUnit, kMultiChannelMixerParam_Volume, kAudioUnitScope_Input, UInt32(index), volume, 0))
  }

  /**
   Apply the current pan setting to the mixer AudioUnit
   */
  fileprivate func applyPan() {
    precondition(mixerUnit != nil)
    guard ready else { return }
    _ = IsAudioError("AudioUnitSetParameter(Pan)",
                     AudioUnitSetParameter(mixerUnit, kMultiChannelMixerParam_Pan, kAudioUnitScope_Input, UInt32(index), pan, 0))
  }

  /**
   Apply the muted setting to the mixer AudioUnit
   */
  fileprivate func applyMuted() {
    precondition(mixerUnit != nil);
    guard ready else { return }
    let result: Float = muted ? 0.0 : 1.0
    _ = IsAudioError("AudioUnitSetParameter(Enable)",
                     AudioUnitSetParameter(mixerUnit, kMultiChannelMixerParam_Enable, kAudioUnitScope_Input, UInt32(index), result, 0))
  }

  /**
   Change notification for solo state of an instrument.

   - parameter instrument: the Instrument that is the solo instrument
   - parameter active: true if solo is active
   */
  public func solo(_ instrument: Instrument, active: Bool) {
    if active {
      soloMutedState = muted
      if self == instrument {
        print("-- solo instrument \(index)")
        muted = false
        solo = true
      }
      else {
        print("-- not solo instrument - muting \(index)")
        muted = true
      }
    }
    else {
      print("-- restoring \(index) \(soloMutedState)")
      muted = soloMutedState
      solo = false
    }
  }

  /**
   Obtain the instrument's configuration settings in an NSData object

   - returns: NSData containing archived configuration values
   */
  public func encodeConfiguration() -> Data {
    let data = NSMutableData()
    let encoder = NSKeyedArchiver(forWritingWith: data)

    encoder.encode(patch.soundFont.name, forKey: "soundFontName")
    encoder.encode(patch.name, forKey: "patchName")
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
  public func configure(with data: Data) -> Bool {
    let decoder = NSKeyedUnarchiver(forReadingWith: data)

    guard let soundFontName = decoder.decodeObject(forKey: "soundFontName") as? String else { return false }
    guard let patchName = decoder.decodeObject(forKey: "patchName") as? String else { return false }
    if let soundFont = SoundFont.library[soundFontName],
       let p = soundFont.findPatch(patchName) {
      patch = p
    }

    octave = decoder.decodeInteger(forKey: "octave")
    volume = decoder.decodeFloat(forKey: "volume")
    pan = decoder.decodeFloat(forKey: "pan")
    muted = decoder.decodeBool(forKey: "muted")

    return true
  }
}
