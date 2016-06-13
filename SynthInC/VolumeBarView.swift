//
//  VolumeBarView.swift
//  SynthInC
//
//  Created by Brad Howes on 6/12/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import UIKit

class VolumeBarView: UIView {

    var volume: Float = 0.0
    var muted: Bool = false

    override func drawRect(rect: CGRect) {
        guard let cgc = UIGraphicsGetCurrentContext() else { return }
        if muted {
            CGContextSetRGBFillColor(cgc, 1, 0, 0, 0.70)
        }
        else {
            CGContextSetRGBFillColor(cgc, 0, 1, 0, 0.70)
        }
        let rect = CGRectMake(bounds.minX, bounds.maxY - 2, bounds.width * CGFloat(volume), 2)
        CGContextFillRect(cgc, rect)
    }
}