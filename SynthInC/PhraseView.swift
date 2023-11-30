// Copyright © 2016 Brad Howes. All rights reserved.

import AVFoundation
import UIKit

/// Graphical depiction of what phrases have been played by an instrument.
final class PhraseView : UIView {

  static let phraseColors: [CGColor] = {
    let phraseColorSaturation: CGFloat = 0.5
    let phraseColorBrightness: CGFloat = 0.95
    let phraseColorAlpha: CGFloat = 1.0
    let hueGenerator: () -> CGFloat = {
      let inverseGoldenRatio: CGFloat = 1.0 / 1.6180339887498948482
      var lastValue: CGFloat = 0.5
      func nextValue() -> CGFloat {
        lastValue = (lastValue + inverseGoldenRatio).truncatingRemainder(dividingBy: 1.0)
        return lastValue
      }
      return nextValue
    }()

    return Score.phrases.map { ($0, UIColor(hue: hueGenerator(), saturation: phraseColorSaturation,
                                            brightness: phraseColorBrightness, alpha: phraseColorAlpha).cgColor).1 }
  }()

  var part: Part! = nil
  var normalizedCurrentPosition: CGFloat = 0.0

  /**
   Draw/update what phrases have been played by an instrument.

   - parameter rect: the area to update
   */
  override func draw(_ rect: CGRect) {
    guard let cgc = UIGraphicsGetCurrentContext() else { return }

    // Draw color bands that show how long a performner stays in each phrase
    var lastX: CGFloat = 0.0
    for (index, duration) in part.normalizedRunningDurations.enumerated() {
      let color = PhraseView.phraseColors[index]
      cgc.setFillColor(color)
      let x = duration * bounds.width
      let rect = CGRect(x: lastX, y: bounds.minY, width: x - lastX, height: bounds.height)
      lastX = x
      cgc.fill(rect)
    }

    // Draw indicator showing playback position
    cgc.setFillColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.30)
    let x = bounds.width * normalizedCurrentPosition
    let rect = CGRect(x: 0, y: bounds.minY, width: x, height: bounds.height)
    cgc.fill(rect)

    cgc.setFillColor(red: 1.0, green: 1.0, blue: 0.0, alpha: 1.0)
    cgc.fill(CGRect(x: x - 2, y: bounds.midY - 8, width: 4, height: 16))
  }
}
