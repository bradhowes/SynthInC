// Adapted from code by Gene De Lisa (Copyright © 2016)

import Foundation
import AVFoundation

/**
 Interrogate an OSStatus value and if an error, report out a textual representation of it

 - parameter method: description of the method that was called
 - parameter error: the OSStatus value to look at

 - returns: true if there was an error
 */
public func IsAudioError(_ method: String, _ error:OSStatus) -> Bool {
  func printError(_ err: String) { print("*** \(method): error \(err)") }
  switch(error) {
  case 0: print("-- \(method): OK"); return false
  case kAUGraphErr_NodeNotFound: printError("kAUGraphErr_NodeNotFound")
  case kAUGraphErr_OutputNodeErr: printError("kAUGraphErr_OutputNodeErr")
  case kAUGraphErr_InvalidConnection: printError("kAUGraphErr_InvalidConnection")
  case kAUGraphErr_CannotDoInCurrentContext: printError("kAUGraphErr_CannotDoInCurrentContext")
  case kAUGraphErr_InvalidAudioUnit: printError("kAUGraphErr_InvalidAudioUnit")
  case kAudioToolboxErr_InvalidSequenceType: printError("kAudioToolboxErr_InvalidSequenceType")
  case kAudioToolboxErr_TrackIndexError: printError("kAudioToolboxErr_TrackIndexError")
  case kAudioToolboxErr_TrackNotFound: printError("kAudioToolboxErr_TrackNotFound")
  case kAudioToolboxErr_EndOfTrack: printError("kAudioToolboxErr_EndOfTrack")
  case kAudioToolboxErr_StartOfTrack: printError("kAudioToolboxErr_StartOfTrack")
  case kAudioToolboxErr_IllegalTrackDestination: printError("kAudioToolboxErr_IllegalTrackDestination")
  case kAudioToolboxErr_NoSequence: printError("kAudioToolboxErr_NoSequence")
  case kAudioToolboxErr_InvalidEventType: printError("kAudioToolboxErr_InvalidEventType")
  case kAudioToolboxErr_InvalidPlayerState: printError("kAudioToolboxErr_InvalidPlayerState")
  case kAudioUnitErr_InvalidProperty: printError("kAudioUnitErr_InvalidProperty")
  case kAudioUnitErr_InvalidParameter: printError("kAudioUnitErr_InvalidParameter")
  case kAudioUnitErr_InvalidElement: printError("kAudioUnitErr_InvalidElement")
  case kAudioUnitErr_NoConnection: printError("kAudioUnitErr_NoConnection")
  case kAudioUnitErr_FailedInitialization: printError("kAudioUnitErr_FailedInitialization")
  case kAudioUnitErr_TooManyFramesToProcess: printError("kAudioUnitErr_TooManyFramesToProcess")
  case kAudioUnitErr_InvalidFile: printError("kAudioUnitErr_InvalidFile")
  case kAudioUnitErr_FormatNotSupported: printError("kAudioUnitErr_FormatNotSupported")
  case kAudioUnitErr_Uninitialized: printError("kAudioUnitErr_Uninitialized")
  case kAudioUnitErr_InvalidScope: printError("kAudioUnitErr_InvalidScope")
  case kAudioUnitErr_PropertyNotWritable: printError("kAudioUnitErr_PropertyNotWritable")
  case kAudioUnitErr_InvalidPropertyValue: printError("kAudioUnitErr_InvalidPropertyValue")
  case kAudioUnitErr_PropertyNotInUse: printError("kAudioUnitErr_PropertyNotInUse")
  case kAudioUnitErr_Initialized: printError("kAudioUnitErr_Initialized")
  case kAudioUnitErr_InvalidOfflineRender: printError("kAudioUnitErr_InvalidOfflineRender")
  case kAudioUnitErr_Unauthorized: printError("kAudioUnitErr_Unauthorized")
  default: printError("unknown (\(error))")
  }
  return true
}
