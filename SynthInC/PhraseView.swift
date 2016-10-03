//
//  PhraseView.swift
//  SynthInC
//
//  Created by Brad Howes on 6/16/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation

/// Graphical depiction of what phrases have been played by an instrument.
class PhraseView : UIView {

    /// The active phrase of the instrument
    var currentPhrase: Int = 1

    /**
     Draw/update what phrases have been played by an instrument.
     
     - parameter rect: the area to update
     */
    override func draw(_ rect: CGRect) {
        guard let cgc = UIGraphicsGetCurrentContext() else { return }
        cgc.setFillColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.20)
        let rect = CGRect(x: bounds.minX, y: bounds.minY, width: bounds.width * CGFloat(currentPhrase - 1) / 53.0, height: bounds.height)
        cgc.fill(rect)
    }
}
