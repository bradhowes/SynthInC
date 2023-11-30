// Copyright © 2016 Brad Howes. All rights reserved.

import Foundation
import AVFoundation

struct Performance {
  let parts: [Part]

  init(perfGen: PerformanceGenerator) {
    self.parts = perfGen.generate()
  }

  init?(data: Data) {
    guard let decoder = try? NSKeyedUnarchiver(forReadingFrom: data) else { return nil }
    guard let configs = decoder.decodeObject(forKey: "parts") as? [Data] else { return nil }
    let parts = configs.compactMap{ Part(data: $0) }
    guard configs.count == parts.count else { return nil }
    self.parts = parts
  }

  func encodePerformance() -> Data {
    let encoder = NSKeyedArchiver(requiringSecureCoding: false)
    encoder.encode(parts.map { $0.encodePerformance() }, forKey: "parts")
    encoder.finishEncoding()
    return encoder.encodedData
  }
}
