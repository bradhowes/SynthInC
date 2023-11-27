//
//  PhraseTests.swift
//  PhraseTests
//
//  Created by Brad Howes on 7/13/18.
//  Copyright © 2018 Brad Howes. All rights reserved.
//

import AVFoundation
import XCTest
@testable import SynthInC

class PhraseTests: XCTestCase {
    
    func test() {
        let n1 = Note(.C5, .whole)
        let n2 = Note(.D5, .half)
        let n3 = Note(.E5, .quarter)
        let phrase = Phrase(n1, n2, n3)
        XCTAssertEqual(phrase.duration, 7.0) // 7 quarter note beats (4 + 2 + 1)
        var musicSequence: MusicSequence?
        XCTAssertEqual(NewMusicSequence(&musicSequence), 0)
        XCTAssertNotNil(musicSequence)

        var musicTrack: MusicTrack?
        XCTAssertEqual(MusicSequenceNewTrack(musicSequence!, &musicTrack), 0)
        
        let c1 = 0.0
        let c2 = phrase.record(clock: c1) { $1.addToTrack(musicTrack!, clock: $0) }
        XCTAssertEqual(c2, c1 + phrase.duration)
    }
}
