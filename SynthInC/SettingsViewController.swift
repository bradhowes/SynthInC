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

class SettingsViewController : IASKAppSettingsViewController {

    override func viewWillAppear(animated: Bool) {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        userDefaults.setInteger(Parameters.randomSeed, forKey: DefaultsKeys.randomSeed._key)
        userDefaults.setInteger(Parameters.noteTimingSlop, forKey: DefaultsKeys.noteTimingSlop._key)
        userDefaults.setDouble(Parameters.seqRepNorm, forKey: DefaultsKeys.seqRepNorm._key)
        userDefaults.setDouble(Parameters.seqRepVar, forKey: DefaultsKeys.seqRepVar._key)
        super.viewWillAppear(animated)
    }

    override func viewWillDisappear(animated: Bool) {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        Parameters.randomSeed = userDefaults.integerForKey(DefaultsKeys.randomSeed._key)
        Parameters.noteTimingSlop = userDefaults.integerForKey(DefaultsKeys.noteTimingSlop._key)
        Parameters.seqRepNorm = userDefaults.doubleForKey(DefaultsKeys.seqRepNorm._key)
        Parameters.seqRepVar = userDefaults.doubleForKey(DefaultsKeys.seqRepVar._key)
        Parameters.dump()
        super.viewWillDisappear(animated)
    }
}
