//
//  SoundFontTests.swift
//  SoundFontTests
//
//  Created by Brad Howes on 7/13/18.
//  Copyright © 2018 Brad Howes. All rights reserved.
//

import XCTest
@testable import SwiftMIDI

class SoundFontTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testLibrary() {
        XCTAssert(SoundFont.keys.count == 4)
        for key in SoundFont.keys {
            guard let soundFont = SoundFont.library[key] else { XCTFail(); return }
            XCTAssertEqual(key, soundFont.name)
            XCTAssertNotNil(soundFont.fileName)
            XCTAssertNotNil(soundFont.fileURL)
            XCTAssert(soundFont.patches.count > 0)
            XCTAssert(soundFont.nameWidth > 0.0)
            XCTAssert(soundFont.maxPatchNameWidth > 0.0)
            XCTAssert(soundFont.nameWidth <= SoundFont.maxNameWidth)
            for patch in soundFont.patches {
                XCTAssert(patch.name.count > 0)
                XCTAssert(patch.nameWidth > 0.0)
                XCTAssert(patch.nameWidth <= soundFont.maxPatchNameWidth)
                XCTAssert(patch.bank >= 0)
                XCTAssert(patch.patch >= 0)
                XCTAssert(patch.soundFont === soundFont)
            }
        }
    }
    
    func testSoundFontFinding() {
        var counter = 0
        for key in SoundFont.keys {
            XCTAssertEqual(SoundFont.indexForName(key), counter)
            let soundFont = SoundFont.getByIndex(counter)
            XCTAssert(soundFont === SoundFont.library[key])
            counter += 1
        }
        
        XCTAssertEqual(SoundFont.indexForName("This is a nonsense name"), 0)
        XCTAssert(SoundFont.getByIndex(-1) === SoundFont.getByIndex(0))
    }
    
    func testPatchFinding() {
        let soundFont = SoundFont.getByIndex(0)
        let patch = soundFont.patches[0]
        XCTAssertEqual(soundFont.findPatchIndex(patch.name), 0)
        XCTAssert(patch === soundFont.findPatch(patch.name))
        XCTAssertNil(soundFont.findPatchIndex("blahblahblahblah"))
        XCTAssertNil(soundFont.findPatch("blahblahblahblah"))
    }
}
