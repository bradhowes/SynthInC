// Copyright © 2018 Brad Howes. All rights reserved.

import Foundation
import SwiftMIDI

/**
 Custom UISlider that allows for taps on the track to jump to a value rather than having to always drag the
 thumb to the position.
 */
class CustomSlider : UISlider
{
  private var trackRect: CGRect { trackRect(forBounds: bounds) }
  private var thumbRect: CGRect { thumbRect(forBounds: bounds, trackRect: trackRect, value: 0.0) }

  override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
    let track = self.trackRect
    let thumb = self.thumbRect
    let pos = touch.location(in: self)
    let normalizedValue = Float((pos.x - track.minX - thumb.width / 2.0) / (track.width - thumb.width))
    self.setValue(minimumValue + (maximumValue - minimumValue) * normalizedValue, animated: true)
    return true
  }
}
