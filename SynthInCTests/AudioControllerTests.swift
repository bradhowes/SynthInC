//
//  AudioControllerTests.swift
//  SwiftMIDITests
//
//  Created by Brad Howes on 8/1/18.
//  Copyright © 2018 Brad Howes. All rights reserved.
//

import XCTest
import AVFoundation
@testable import SynthInC

@MainActor
class AudioControllerTests: XCTestCase {

    var audioController: AudioController?

    override func setUp() {
        super.setUp()
 
        audioController = AudioController()
//
//        let exp = expectation(description: "\(#function)\(#line)")
//        audioController?.createEnsemble(ensembleSize: 1, instrumentDoneCallback: { index in }) {
//            exp.fulfill()
//        }
//
//        waitForExpectations(timeout: 40, handler: nil)
    }

    override func tearDown() {
        super.tearDown()
        audioController = nil
    }

    func testCreateEnsemble() {
        
        let instrumentDone = expectation(description: "instrumentDone")
        let finished = expectation(description: "finished")
        audioController?.createEnsemble(ensembleSize: 1, instrumentDoneCallback: { index in
            XCTAssertEqual(index, 0)
            instrumentDone.fulfill()
        }) { done in
            XCTAssertTrue(done)
            finished.fulfill()
        }

        waitForExpectations(timeout: 40, handler: nil)
    }
    
    func testRestoreEnsemble() {
        let finished1 = expectation(description: "finished1")
        audioController?.createEnsemble(ensembleSize: 2, instrumentDoneCallback: { index in
        }) { done in
            XCTAssertTrue(done)
            finished1.fulfill()
        }

        waitForExpectations(timeout: 40, handler: nil)

        var instrument = audioController!.ensemble[0]
        let oldPatch = instrument.patch
        let newPatch = SoundFont.library[SoundFont.keys[0]]!.patches[10]
        XCTAssertFalse(oldPatch === newPatch)

        instrument.patch = newPatch

        let data = audioController!.encodeEnsemble()
        XCTAssertNotNil(data)

        instrument.patch = oldPatch

        let finished2 = expectation(description: "finished2")

        audioController?.restoreEnsemble(data: data, instrumentDoneCallback: { index in
        }) { done in
            XCTAssertTrue(done)
            finished2.fulfill()
        }

        waitForExpectations(timeout: 40, handler: nil)

        XCTAssertEqual(audioController!.ensemble.count, 2)

        instrument = audioController!.ensemble[0]
        XCTAssertTrue(instrument.patch === newPatch)
    }
}
