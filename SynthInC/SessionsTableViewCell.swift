// SessionsTableViewCell.swift
// SynthInC
//
// Created by Brad Howes on 6/4/16.
// Copyright © 2016 Brad Howes. All rights reserved.

import UIKit
import AVFoundation

/// Simple derivation of UITableViewCell for the instruments view.
final class SessionsTableViewCell: UITableViewCell {
  
  @IBOutlet weak var title: UILabel!
  @IBOutlet weak var subtitle: UILabel!
  
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
}
