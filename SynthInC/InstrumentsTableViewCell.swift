// InstrumentsTableViewCell.swift
// SynthInC
//
// Created by Brad Howes on 6/4/16.
// Copyright © 2016 Brad Howes. All rights reserved.

import UIKit

/// Simple derivation of UITableViewCell for the instruments view.
class InstrumentsTableViewCell: UITableViewCell {

    @IBOutlet weak var instrumentIndex: UILabel!
    @IBOutlet weak var patchName: UILabel!
    @IBOutlet weak var soundFontName: UILabel!
    @IBOutlet weak var phrase: UILabel!
    @IBOutlet weak var volumeLevel: VolumeBarView!

    /**
     Customize the UI after the view is created from the NIB file.
     */
    override func awakeFromNib() {
        super.awakeFromNib()

        // Set up a custom selection color
        let selectionColor = UIView()
        selectionColor.backgroundColor = UIColor(colorLiteralRed:1.0, green:1.0, blue:1.0, alpha:0.2)
        selectedBackgroundView = selectionColor

        // !!! Need this here or else the accessory view does not use the same background color
        backgroundColor = UIColor(colorLiteralRed:(48/255.0), green:0.0, blue:(109/255.0), alpha:1)
    }
}
