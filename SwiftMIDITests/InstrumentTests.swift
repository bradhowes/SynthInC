//
//  InstrumentTests.swift
//  SwiftMIDITests
//
//  Created by Brad Howes on 8/1/18.
//  Copyright © 2018 Brad Howes. All rights reserved.
//

import XCTest
import AVFoundation
@testable import SwiftMIDI

class InstrumentTests: XCTestCase {

    var audioController: AudioController?

    override func setUp() {
        super.setUp()
        audioController = AudioController()
        let exp = expectation(description: "\(#function)\(#line)")
        audioController?.createEnsemble(ensembleSize: 2, instrumentDoneCallback: { index in }) { done in
            exp.fulfill()
        }

        waitForExpectations(timeout: 40, handler: nil)
    }

    override func tearDown() {
        super.tearDown()
        audioController = nil
    }

    func testInstrumentConfiguration() {
        XCTAssert(audioController != nil)
        let instrument = audioController!.ensemble[0]
        let patch0 = SoundFont.library[SoundFont.keys[0]]!.patches[0]
        
        instrument.patch = patch0
        instrument.octave = -1
        instrument.volume = 0.25
        instrument.pan = -1.0
        instrument.muted = true

        let config = instrument.encodeConfiguration()
        
        instrument.patch = SoundFont.library[SoundFont.keys[0]]!.patches[1]
        instrument.octave = 1
        instrument.volume = 0.75
        instrument.pan = 1.0
        instrument.muted = false
        
        XCTAssertTrue(instrument.configure(with: config))
        
        XCTAssert(instrument.patch === patch0)
        XCTAssertEqual(instrument.octave, -1)
        XCTAssertEqual(instrument.volume, 0.25)
        XCTAssertEqual(instrument.pan, -1.0)
        XCTAssertEqual(instrument.muted, true)
    }
}
