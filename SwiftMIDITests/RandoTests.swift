//
//  RandoTests.swift
//  RandoTests
//
//  Created by Brad Howes on 7/13/18.
//  Copyright © 2018 Brad Howes. All rights reserved.
//

import AVFoundation
import XCTest
@testable import SwiftMIDI

class RandoTests: XCTestCase {
   
    func testRepeatability() {
        let randoConfig = RandomSources.Config(seed: 123)
        let r1 = RandomSources(config: randoConfig)
        let r2 = RandomSources(config: randoConfig)
        for _ in 0..<1000 {
            XCTAssertEqual(r1.uniform(), r2.uniform())
        }
    }

    func testNonRepeatability() {
        let randoConfig = RandomSources.Config(seed: 0)
        let r1 = RandomSources(config: randoConfig)
        let r2 = RandomSources()
        for _ in 0..<1000 {
            XCTAssertNotEqual(r1.uniform(), r2.uniform())
        }
    }
}
