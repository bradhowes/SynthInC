// Copyright © 2016 Brad Howes. All rights reserved.

import UIKit

/// Custom UIView for showing Instrument volume and pan setting
final class VolumeBarView: UIView {
  
  var volume: Float = 0.0
  var pan: Float = 0.0
  var muted: Bool = false
  
  /**
   Drawing routine to show the volume and pan settings.
   
   - parameter rect: area to update
   */
  override func draw(_ rect: CGRect) {
    guard let cgc = UIGraphicsGetCurrentContext() else { return }
    
    // Fill the entire view
    //
    cgc.setFillColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.20)
    cgc.fill(bounds)
    
    // Set the volume color depending on mute status
    //
    if muted {
      cgc.setFillColor(red: 0.8, green: 0, blue: 0, alpha: 0.80)
    }
    else {
      cgc.setFillColor(red: 0.2, green: 0.8, blue: 0.2, alpha: 0.80)
    }
    
    // Draw the bar for volume
    let w = bounds.width
    let rect = CGRect(x: bounds.minX, y: bounds.minY, width: w * CGFloat(volume), height: bounds.height)
    cgc.fill(rect)
    
    // Draw a small indicator for the pan
    //
    let px = bounds.minX + w * CGFloat((pan + 1.0) / 2.0)
    cgc.setFillColor(red: 1, green: 1, blue: 1, alpha: 0.90)
    cgc.fill(CGRect(x: px - 2, y: bounds.minY, width: 4, height: bounds.height))
  }
}
