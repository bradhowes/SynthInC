// Copyright © 2016 Brad Howes. All rights reserved.

import Foundation
import AVFoundation

/**
 Helper function that simply sets the sample rate for a give AudioUnit to 44100

 - parameter au: the AudioUnit to set

 - returns: true if successful, false otherwise
 */
internal func setAudioUnitSampleRate(_ au: AudioUnit) -> Bool {
  var sampleRate: Float64 = 44100.0;
  if IsAudioError("AudioUnitSetProperty(sampleRate)",
                  AudioUnitSetProperty(au,
                                       kAudioUnitProperty_SampleRate,
                                       kAudioUnitScope_Output,
                                       0,
                                       &sampleRate,
                                       UInt32(MemoryLayout.size(ofValue: sampleRate)))) {
    return false
  }
  return true
}
