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
    override func drawRect(rect: CGRect) {
        guard let cgc = UIGraphicsGetCurrentContext() else { return }
        CGContextSetRGBFillColor(cgc, 1.0, 1.0, 1.0, 0.20)
        let rect = CGRectMake(bounds.minX, bounds.minY, bounds.width * CGFloat(currentPhrase - 1) / 53.0, bounds.height)
        CGContextFillRect(cgc, rect)
    }
}