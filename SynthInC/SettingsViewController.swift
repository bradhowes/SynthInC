//
//  SettingsViewController.swift
//  SynthInC
//
//  Created by Brad Howes on 6/16/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import UIKit
import InAppSettingsKit
import SwiftyUserDefaults

/// Slight derivation of `IASKAppSettingsViewController` in order to marshal settings.
final class SettingsViewController : IASKAppSettingsViewController {

    /**
     Update NSUserDefaults values using values from Parameters class
     
     - parameter animated: true if the view should animate its appearance
     */
    override func viewWillAppear(_ animated: Bool) {
        let userDefaults = UserDefaults.standard
        userDefaults.set(Parameters.randomSeed, forKey: DefaultsKeys.randomSeed._key)
        userDefaults.set(Parameters.maxInstrumentCount, forKey: DefaultsKeys.maxInstrumentCount._key)
        userDefaults.set(Parameters.noteTimingSlop, forKey: DefaultsKeys.noteTimingSlop._key)
        userDefaults.set(Parameters.seqRepNorm, forKey: DefaultsKeys.seqRepNorm._key)
        userDefaults.set(Parameters.seqRepVar, forKey: DefaultsKeys.seqRepVar._key)
        super.viewWillAppear(animated)
    }

    /**
     Update the Parameters class instances using values from NSUserDefaults
     
     - parameter animated: true if the view snould animate its disappearance
     */
    override func viewWillDisappear(_ animated: Bool) {
        let userDefaults = UserDefaults.standard
        Parameters.randomSeed = userDefaults.integer(forKey: DefaultsKeys.randomSeed._key)
        Parameters.maxInstrumentCount = userDefaults.integer(forKey: DefaultsKeys.maxInstrumentCount._key)
        Parameters.noteTimingSlop = userDefaults.integer(forKey: DefaultsKeys.noteTimingSlop._key)
        Parameters.seqRepNorm = userDefaults.double(forKey: DefaultsKeys.seqRepNorm._key)
        Parameters.seqRepVar = userDefaults.double(forKey: DefaultsKeys.seqRepVar._key)
        Parameters.dump()
        super.viewWillDisappear(animated)
    }
}
