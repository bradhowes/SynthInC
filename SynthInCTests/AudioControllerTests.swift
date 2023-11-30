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
  }

  override func tearDown() {
    super.tearDown()
    audioController = nil
  }

  func testCreateEnsemble() {
    let instrumentDone = expectation(description: "instrumentDone")
    instrumentDone.expectedFulfillmentCount = 2
    let finished = expectation(description: "finished")
    var obsToken1: NSObjectProtocol! = nil
    obsToken1 = NotificationCenter.default.addObserver(forName: .ensembleReady, object: nil, queue: nil) { _ in
      finished.fulfill()
    }

    var obsToken2: NSObjectProtocol! = nil
    obsToken2 = NotificationCenter.default.addObserver(forName: .instrumentReady, object: nil, queue: nil) { _ in
      instrumentDone.fulfill()
    }

    audioController?.createEnsemble(ensembleSize: 2)
    waitForExpectations(timeout: 40, handler: nil)

    NotificationCenter.default.removeObserver(obsToken1!)
    NotificationCenter.default.removeObserver(obsToken2!)
  }

  func testRestoreEnsemble() {
    let finished1 = expectation(description: "finished1")
    var obsToken1: NSObjectProtocol? = nil
    obsToken1 = NotificationCenter.default.addObserver(forName: .ensembleReady, object: nil, queue: nil) { _ in
      finished1.fulfill()
    }
    audioController?.createEnsemble(ensembleSize: 2)
    wait(for: [finished1], timeout: 10)
    NotificationCenter.default.removeObserver(obsToken1!)

    let finished2 = expectation(description: "finished2")
    var obsToken2: NSObjectProtocol? = nil
    obsToken2 = NotificationCenter.default.addObserver(forName: .ensembleReady, object: nil, queue: nil) { _ in
      finished2.fulfill()
    }

    var instrument = audioController!.ensemble[0]
    let oldPatch = instrument.patch
    let newPatch = SoundFont.library[SoundFont.keys[0]]!.patches[10]
    XCTAssertFalse(oldPatch === newPatch)

    instrument.patch = newPatch
    let data = audioController!.encodeEnsemble()
    XCTAssertNotNil(data)

    instrument.patch = oldPatch

    audioController?.restoreEnsemble(data: data)

    wait(for: [finished2], timeout: 40)
    NotificationCenter.default.removeObserver(obsToken2!)

    XCTAssertEqual(audioController!.ensemble.count, 2)
    instrument = audioController!.ensemble[0]
    XCTAssertTrue(instrument.patch === newPatch)
  }
}
