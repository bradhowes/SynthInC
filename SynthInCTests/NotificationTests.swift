//
//  PhraseTests.swift
//  PhraseTests
//
//  Created by Brad Howes on 7/13/18.
//  Copyright © 2018 Brad Howes. All rights reserved.
//

import Foundation
import XCTest
@testable import SynthInC

class NotificationTests: XCTestCase {

  func testNotification() {
    let name = Notification.Name(rawValue: "BoolNotification")
    let tn = TypedNotification<Bool>(name: name)

    let expTrue = self.expectation(description: "saw true")
    let expFalse = self.expectation(description: "saw false")
    let obs = tn.registerOnAny { successful in
      if successful {
        expTrue.fulfill()
      } else {
        expFalse.fulfill()
      }
    }

    XCTAssertNotNil(obs)
    tn.post(value: true)
    tn.post(value: false)

    wait(for: [expTrue, expFalse])
  }

  func testForget() {
    let name = Notification.Name(rawValue: "BoolNotification")
    let tn = TypedNotification<Bool>(name: name)

    let exp = self.expectation(description: "saw true")
    exp.isInverted = true
    let obs = tn.registerOnAny { successful in
      exp.fulfill()
    }
    XCTAssertNotNil(obs)

    obs.forget()
    tn.post(value: true)

    wait(for: [exp], timeout: 5.0)
  }

  func testComplexCodable() {
    let name = Notification.Name(rawValue: "ComplexNotification")
    let tn = TypedNotification<Complex>(name: name)

    let exp = self.expectation(description: "saw")
    let val = Complex(a: "hello", b: 3.14, c: [3,2,1], d: 123, e: ["one": 1, "two": 2, "three": 3])
    let obs = tn.registerOnAny { value in
      XCTAssertEqual(val, value)
      exp.fulfill()
    }

    XCTAssertNotNil(obs)
    tn.post(value: val)

    wait(for: [exp])
  }
}

struct Complex: Codable, Equatable {
  let a: String
  let b: Float
  let c: [Int]
  let d: Int32
  let e: [String: Int]
}
