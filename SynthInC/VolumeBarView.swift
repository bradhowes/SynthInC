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
    var pan: Float = 0.0
    var muted: Bool = false

    override func drawRect(rect: CGRect) {
        guard let cgc = UIGraphicsGetCurrentContext() else { return }
        //        CGContextSetFillColorWithColor(cgc, backgroundColor?.CGColor)

        CGContextSetRGBFillColor(cgc, 1.0, 1.0, 1.0, 0.20)
        CGContextFillRect(cgc, bounds)

        if muted {
            CGContextSetRGBFillColor(cgc, 0.8, 0, 0, 0.80)
        }
        else {
            CGContextSetRGBFillColor(cgc, 0.2, 0.8, 0.2, 0.80)
        }

        let w = bounds.width
        let rect = CGRectMake(bounds.minX, bounds.minY, w * CGFloat(volume), bounds.height)
        CGContextFillRect(cgc, rect)
        let px = bounds.minX + w * CGFloat((pan + 1.0) / 2.0)
        CGContextSetRGBFillColor(cgc, 1, 1, 1, 0.90)
        CGContextFillRect(cgc, CGRectMake(px - 2, bounds.minY, 4, bounds.height))
    }
}