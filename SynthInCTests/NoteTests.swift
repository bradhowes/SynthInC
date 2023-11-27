//
//  NoteTests.swift
//  NoteTests
//
//  Created by Brad Howes on 7/13/18.
//  Copyright © 2018 Brad Howes. All rights reserved.
//

import AVFoundation
import XCTest
@testable import SynthInC

class NoteTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testConstruction() {
        XCTAssertEqual(Duration.quarter, 480)
        let n1 = Note(.A4, .quarter)
        XCTAssertEqual(n1.note, NoteValue.A4)
        XCTAssertEqual(n1.duration, Duration.quarter.scaled)
        let n2 = Note(.A4, 480)
        XCTAssertEqual(n1.note, n2.note)
        XCTAssertEqual(n1.duration, n2.duration)
    }

    func testDuration() {
        XCTAssertEqual(Duration.quarter, 480)
        XCTAssertEqual(Duration.quarter * 2, Duration.half)
        XCTAssertEqual(Duration.quarter / 2, Duration.eighth)
        let n1 = Note(.C5, .whole)
        XCTAssertEqual(n1.note, NoteValue.C5)
        XCTAssertEqual(n1.duration, Duration.whole.scaled)
        
        let clock = 100.0
        XCTAssertEqual(n1.getStartTime(clock: clock, slop: 0.0), clock)

        let n2 = Note(.C5, -.whole)
        XCTAssert(n2.isGraceNote)
        XCTAssertEqual(n2.duration, Duration.whole.scaled)
        XCTAssertEqual(n2.getStartTime(clock: clock, slop: 0.0), 100 - n2.duration)
    }
    
    func testGetStartTime() {
        let clock = 100.0
        let s1 = 0.1
        let s2 = -0.2
        let n1 = Note(.C5, .quarter)
        XCTAssertEqual(n1.getStartTime(clock: clock, slop: s1), clock + s1)
        XCTAssertEqual(n1.getStartTime(clock: clock, slop: s2), clock + s2)
        let n2 = Note(.C5, -.quarter)
        XCTAssertEqual(n2.getStartTime(clock: clock, slop: s1), clock - n2.duration)
        XCTAssertEqual(n2.getStartTime(clock: clock, slop: s2), clock - n2.duration)
    }

    func testGetEndTime() {
        let n1 = Note(.C5, .whole)
        let n2 = Note(.D5, .half)
        let n3 = Note(.E5, .quarter)

        var musicSequence: MusicSequence? = nil
        XCTAssertEqual(NewMusicSequence(&musicSequence), 0)
        XCTAssertNotNil(musicSequence)

        var musicTrack: MusicTrack?
        XCTAssertEqual(MusicSequenceNewTrack(musicSequence!, &musicTrack), 0)
        
        let c1 = 0.0
        let c2 = n1.getEndTime(clock: c1)
        let c3 = n2.getEndTime(clock: c2)
        let c4 = n3.getEndTime(clock: c3)

        XCTAssertEqual(c2, c1 + n1.duration)
        XCTAssertEqual(c3, c2 + n2.duration)
        XCTAssertEqual(c4, c3 + n3.duration)
    }
}
