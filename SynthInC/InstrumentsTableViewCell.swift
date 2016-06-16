// InstrumentsTableViewCell.swift
// SynthInC
//
// Created by Brad Howes on 6/4/16.
// Copyright © 2016 Brad Howes. All rights reserved.

import UIKit
import AVFoundation

/// Simple derivation of UITableViewCell for the instruments view.
class InstrumentsTableViewCell: UITableViewCell {

    weak var instrument: Instrument!

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
        backgroundColor = UIColor(colorLiteralRed:(48/255.0), green:0.0, blue:(109/255.0), alpha:1)
        
        // Set up a custom selection color
        let selectionColor = UIView()
        selectionColor.backgroundColor = UIColor(colorLiteralRed:1.0, green:1.0, blue:1.0, alpha:0.2)
        selectedBackgroundView = selectionColor
    }
    
    /**
     Update the view components.
     
     - parameter currentPosition: the playback position of the active MusicPlayer
     */
    func updateAll(currentPosition: MusicTimeStamp) {
        updateTitle()
        updateSoundFontName()
        updateVolume()
        updatePhrase(currentPosition)
    }

    func updateTitle() {
        let value = Int(instrument.octave)
        let octaveTag = value != 0 ? " (\(value > 0 ? "+" : "")\(Int(value)))" : ""
        patchName?.text = instrument.patch.name + octaveTag
    }

    func updateSoundFontName() {
        soundFontName?.text = instrument.patch.soundFont?.name
    }

    func updateVolume() {
        volumeLevel.muted = instrument.muted
        volumeLevel.volume = instrument.volume
        volumeLevel.pan = instrument.pan
        volumeLevel.setNeedsDisplay()
    }

    /**
     Update the phrase label that shows the current score phrase being played by an Instrument.
     
     - parameter currentPosition: the playback position of the active MusicPlayer
     */
    func updatePhrase(currentPosition: MusicTimeStamp) {
        let phraseIndex = instrument.getSectionPlaying(currentPosition)
        phrase?.text = phraseIndex >= 0 ? "p.\(phraseIndex)" : ""
    }
    
    func updateInstrumentIndex(index: Int) {
        instrumentIndex.text = "\(index)"
    }
}
