//
//  Notifications.swift
//  SynthInC
//
//  Created by Brad Howes on 30/11/2023.
//  Copyright © 2023 Brad Howes. All rights reserved.
//

import Foundation

extension Notification.Name {
  static let instrumentReady: Notification.Name = .init("instrumentReady")
  static let ensembleReady: Notification.Name = .init("ensembleReady")
}
