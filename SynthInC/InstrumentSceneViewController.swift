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

    fileprivate var scene: SKScene! = nil

    override func viewDidLoad() {
        sceneView.showsFPS = true
        sceneView.showsNodeCount = true
        sceneView.showsDrawCount = true
        setNeedsStatusBarAppearanceUpdate()
    
        scene = SKScene(size: sceneView.frame.size)

        audioController.activeInstruments.forEach {
            print($0)
            // makeInstrumentNode($0)
        }

        super.viewDidLoad()
    }

    /**
     Tell the OS that we have a dark background
     
     - returns: UIStatusBarStyle.LigthContent
     */
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }

//    func makeInstrumentNode(_ instrument: Instrument) {
//        let path = CGMutablePath()
//        //        path.addAr
//        //        CGPathAddArc(path, UnsafePointer<CGAffineTransform>(bitPattern: 0)!, 0, 0, 15, 0, CGFloat(M_PI * 2.0), true)
//        //        let ball = SKShapeNode(path: path)
//        //        ball.lineWidth = 1.0;
//        //        ball.fillColor = SKColor.blue
//        //        ball.strokeColor = SKColor.white
//        //        ball.glowWidth = 0.5
//        
//        scene.addChild(ball)
//    }
}
