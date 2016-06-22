//
//  InstrumentSceneViewController.swift
//  SynthInC
//
//  Created by Brad Howes on 6/17/16.
//  Copyright © 2016 Brad Howes. All rights reserved.
//

import UIKit
import SpriteKit

class InstrumentSceneViewController : UIViewController {
    @IBOutlet weak var sceneView: SKView!

    override func viewDidLoad() {
        sceneView.showsFPS = true
        sceneView.showsNodeCount = true
        sceneView.showsDrawCount = true
        setNeedsStatusBarAppearanceUpdate()
        
        audioController.activeInstruments.forEach {
            print($0)
        }

        super.viewDidLoad()
    }

    /**
     Tell the OS that we have a dark background
     
     - returns: UIStatusBarStyle.LigthContent
     */
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
}
