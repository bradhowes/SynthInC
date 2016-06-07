// CheckError.swift
// SynthInC
//
// Adapted from code by Gene De Lisa (Copyright © 2016)

import Foundation
import AVFoundation

/**
 Interrogate an OSStatus value and if an error, report out a textual representation of it
 
 - parameter method: description of the method that was called
 - parameter error: the OSStatus value to look at
 
 - returns: true if there was an error
 */
func CheckError(method: String, _ error:OSStatus) -> Bool {
    switch(error) {
    case 0:
        // print("-- \(method) OK")
        return false
    case kAUGraphErr_NodeNotFound:
        print("*** error: \(method) \(method) kAUGraphErr_NodeNotFound")
    case kAUGraphErr_OutputNodeErr:
        print( "*** error: \(method) kAUGraphErr_OutputNodeErr")
    case kAUGraphErr_InvalidConnection:
        print("*** error: \(method) kAUGraphErr_InvalidConnection")
    case kAUGraphErr_CannotDoInCurrentContext:
        print( "*** error: \(method) kAUGraphErr_CannotDoInCurrentContext")
    case kAUGraphErr_InvalidAudioUnit:
        print( "*** error: \(method) kAUGraphErr_InvalidAudioUnit")
    case kAudioToolboxErr_InvalidSequenceType:
        print( "*** error: \(method) kAudioToolboxErr_InvalidSequenceType")
    case kAudioToolboxErr_TrackIndexError:
        print( "*** error: \(method) kAudioToolboxErr_TrackIndexError")
    case kAudioToolboxErr_TrackNotFound:
        print( "*** error: \(method) kAudioToolboxErr_TrackNotFound")
    case kAudioToolboxErr_EndOfTrack:
        print( "*** error: \(method) kAudioToolboxErr_EndOfTrack")
    case kAudioToolboxErr_StartOfTrack:
        print( "*** error: \(method) kAudioToolboxErr_StartOfTrack")
    case kAudioToolboxErr_IllegalTrackDestination:
        print( "*** error: \(method) kAudioToolboxErr_IllegalTrackDestination")
    case kAudioToolboxErr_NoSequence:
        print( "*** error: \(method) kAudioToolboxErr_NoSequence")
    case kAudioToolboxErr_InvalidEventType:
        print( "*** error: \(method) kAudioToolboxErr_InvalidEventType")
    case kAudioToolboxErr_InvalidPlayerState:
        print( "*** error: \(method) kAudioToolboxErr_InvalidPlayerState")
    case kAudioUnitErr_InvalidProperty:
        print( "*** error: \(method) kAudioUnitErr_InvalidProperty")
    case kAudioUnitErr_InvalidParameter:
        print( "*** error: \(method) kAudioUnitErr_InvalidParameter")
    case kAudioUnitErr_InvalidElement:
        print( "*** error: \(method) kAudioUnitErr_InvalidElement")
    case kAudioUnitErr_NoConnection:
        print( "*** error: \(method) kAudioUnitErr_NoConnection")
    case kAudioUnitErr_FailedInitialization:
        print( "*** error: \(method) kAudioUnitErr_FailedInitialization")
    case kAudioUnitErr_TooManyFramesToProcess:
        print( "*** error: \(method) kAudioUnitErr_TooManyFramesToProcess")
    case kAudioUnitErr_InvalidFile:
        print( "*** error: \(method) kAudioUnitErr_InvalidFile")
    case kAudioUnitErr_FormatNotSupported:
        print( "*** error: \(method) kAudioUnitErr_FormatNotSupported")
    case kAudioUnitErr_Uninitialized:
        print( "*** error: \(method) kAudioUnitErr_Uninitialized")
    case kAudioUnitErr_InvalidScope:
        print( "*** error: \(method) kAudioUnitErr_InvalidScope")
    case kAudioUnitErr_PropertyNotWritable:
        print( "*** error: \(method) kAudioUnitErr_PropertyNotWritable")
    case kAudioUnitErr_InvalidPropertyValue:
        print( "*** error: \(method) kAudioUnitErr_InvalidPropertyValue")
    case kAudioUnitErr_PropertyNotInUse:
        print( "*** error: \(method) kAudioUnitErr_PropertyNotInUse")
    case kAudioUnitErr_Initialized:
        print( "*** error: \(method) kAudioUnitErr_Initialized")
    case kAudioUnitErr_InvalidOfflineRender:
        print( "*** error: \(method) kAudioUnitErr_InvalidOfflineRender")
    case kAudioUnitErr_Unauthorized:
        print( "*** error: \(method) kAudioUnitErr_Unauthorized")
    default:
        print("*** error: \(method) unknown (\(error))" )
    }
    
    return true
}
