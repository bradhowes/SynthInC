//
//  Utils.swift
//  SynthInC
//
//  Created by Brad Howes on 6/6/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation
import AVFoundation

/**
 Helper function that simply sets the sample rate for a give AudioUnit to 44100
 
 - parameter au: the AudioUnit to set
 
 - returns: true if successful, false otherwise
 */
internal func setAudioUnitSampleRate(au: AudioUnit) -> Bool {
    var sampleRate: Float64 = 44100.0;
    if CheckError("AudioUnitSetProperty(sampleRate)", AudioUnitSetProperty(au, kAudioUnitProperty_SampleRate,
        kAudioUnitScope_Output, 0, &sampleRate, UInt32(sizeofValue(sampleRate)))) {
        return false
    }
    return true
}

extension CollectionType where Index: RandomAccessIndexType {

    /**
     Binary search for a collection. Provides a mechanism for locating the appropriate place to insert into a 
     collection to keep it ordered. Adapted from code found on Stack Overflow in answer to
     ["Swift: Binary search for standard array?"](http://stackoverflow.com/questions/31904396/swift-binary-search-for-standard-array)
     
     - parameter predicate: the ordering operation (eg. `{ $0 < 123 }')
     
     - returns: 2-tuple containing index into collection where ordering would be preserved and the optional value
     currently at that position (nil when index is the size of the collection)
     */
    func binarySearch(predicate: Generator.Element -> Bool) -> (Index, Generator.Element?) {
        var low = startIndex
        var high = endIndex
        while low != high {
            let mid = low.advancedBy(low.distanceTo(high) / 2)
            if predicate(self[mid]) {
                low = mid.advancedBy(1)
            }
            else {
                high = mid
            }
        }

        return (low, low != endIndex ? self[low] : nil)
    }
}

