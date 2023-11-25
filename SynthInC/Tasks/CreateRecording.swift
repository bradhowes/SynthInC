// Copyright © 2018 Brad Howes. All rights reserved.

import Foundation
import SwiftMIDI

class CreateRecording : NSObject
{
  private let audioController: AudioController

  init(audioController: AudioController) {
    self.audioController = audioController
    super.init()
  }
}
