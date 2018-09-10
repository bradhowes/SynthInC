// InstrumentsTableViewCell.swift
// SynthInC
//
// Created by Brad Howes on 6/4/16.
// Copyright © 2016 Brad Howes. All rights reserved.

import UIKit
import AVFoundation
import SwiftMIDI

/// Simple derivation of UITableViewCell for the instruments view.
final class InstrumentCell: UITableViewCell {

    weak var instrument: Instrument!
    weak var part: Part! {
        didSet {
            self.phrases.part = part
        }
    }

    @IBOutlet weak var patchName: UILabel!
    @IBOutlet weak var soundFontName: UILabel!
    @IBOutlet weak var volumeLevel: VolumeBarView!
    @IBOutlet weak var phrases: PhraseView!

    /**
     Customize the UI after the view is created from the NIB file.
     */
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = UIColor(red: 48/255.0, green: 0/255.0, blue: 109/255.0, alpha: 1.0)

        // Set up a custom selection color. Just overlay a white view with %20 opacity.
        let selectionColor = UIView()
        selectionColor.backgroundColor = UIColor(red:1.0, green:1.0, blue:1.0, alpha:0.2)
        selectedBackgroundView = selectionColor
    }

    /**
     Update the view components.
     
     - parameter currentPosition: the playback position of the active MusicPlayer
     */
    func updateAll(_ normalizedCurrentPosition: CGFloat) {
        updateTitle()
        updateSoundFontName()
        updateVolume()
        updatePhrase(normalizedCurrentPosition)
    }

    /**
     Update the patch title. The patch title includes any octave adjustments.
     */
    func updateTitle() {
        let value = Int(instrument.octave)
        let octaveTag = value != 0 ? " (\(value > 0 ? "+" : "")\(Int(value)))" : ""
        patchName?.text = instrument.patch.name + octaveTag
        
        patchName.isEnabled = instrument.ready
        soundFontName.isEnabled = instrument.ready
    }

    /**
     Update the sound font name due to user changes.
     */
    func updateSoundFontName() {
        soundFontName.text = instrument.patch.soundFont?.name
    }

    /**
     Update the volume indicator due to user changes.
     */
    func updateVolume() {
        volumeLevel.isHidden = !instrument.ready
        volumeLevel.muted = instrument.muted
        volumeLevel.volume = instrument.volume
        volumeLevel.pan = instrument.pan
        volumeLevel.setNeedsDisplay()
    }

    /**
     Update the phrase graph that shows the current score phrase being played by an Instrument.

     - parameter currentPosition: the playback position of the active MusicPlayer
     */
    func updatePhrase(_ normalizedCurrentPosition: CGFloat) {
        phrases.normalizedCurrentPosition = normalizedCurrentPosition
        phrases.setNeedsDisplay()
    }
}
