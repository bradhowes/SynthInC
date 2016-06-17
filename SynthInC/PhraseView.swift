//
//  PhraseView.swift
//  SynthInC
//
//  Created by Brad Howes on 6/16/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import Foundation

class PhraseView : UIView {

    var currentPhrase: Int = 1

    override func drawRect(rect: CGRect) {
        guard let cgc = UIGraphicsGetCurrentContext() else { return }
        CGContextSetRGBFillColor(cgc, 1.0, 1.0, 1.0, 0.20)
        let rect = CGRectMake(bounds.minX, bounds.minY, bounds.width * CGFloat(currentPhrase - 1) / 53.0, bounds.height)
        CGContextFillRect(cgc, rect)
    }
}