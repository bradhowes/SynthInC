// Copyright © 2019 Brad Howes. All rights reserved.

import Foundation
import os

/// Typed notification definition. Template argument defines the type of a value that will be transmitted in the
/// notification userInfo["value"] slot. This value will be available to blocks registered to receive it
open class TypedNotification<ValueType: Codable & Sendable> {

  /// The name of the notification
  public let name: Notification.Name

  /**
   Construct a new notification definition.

   - parameter name: the unique name for the notification
   */
  public required init(name: Notification.Name) { self.name = name }

  /**
   Post this notification to all observers of it

   - parameter value: the value to forward to the observers
   */
  open func post(value: ValueType) {
    let encoder = JSONEncoder()
    // encoder.outputFormatting = .prettyPrinted

    if let data = try? encoder.encode(value) {
      print(String(data: data, encoding: .utf8)!)
      NotificationCenter.default.post(name: name, object: self, userInfo: ["encoded": data])
    } else {
      print("*** help me!")
      NotificationCenter.default.post(name: name, object: self, userInfo: ["encoded": Data()])
    }
  }

  /**
   Register an observer to receive this notification definition on any thread.

   - parameter block: a closure to execute when this kind of notification arrives
   - returns: a NotificationObserver instance that records the registration.
   */
  open func registerOnAny(block: @escaping @Sendable (ValueType) -> Void) -> NotificationObserver<ValueType> {
    NotificationObserver(notification: self, block: block)
  }

  /**
   Register for a notification that *only* takes place on the app's main (UI) thread.

   - parameter block: a closure to execute when this kind of notification arrives
   - returns: a NotificationObserver instance that records the registration.
   */
  open func registerOnMain(block: @escaping @Sendable (ValueType) -> Void) -> NotificationObserver<ValueType> {
    NotificationObserver(notification: self) { arg in DispatchQueue.main.async { block(arg) } }
  }
}

/// Manager of a TypedNotification registration. When the instance is no longer being held, it will automatically
/// unregister the internal observer from future notification events.
public class NotificationObserver<ValueType: Codable & Sendable> {
  private let name: Notification.Name
  private var observer: NSObjectProtocol?

  /**
   Create a new observer for the given typed notification
   */
  public init(notification: TypedNotification<ValueType>, block aBlock: @escaping @Sendable (ValueType) -> Void) {
    name = notification.name
    observer = NotificationCenter.default.addObserver(forName: notification.name, object: nil, queue: nil) { note in
      guard let data = note.userInfo?["encoded"] as? Data,
            !data.isEmpty
      else { 
        fatalError("Couldn't understand user info")
      }
      let decoder = JSONDecoder()
      let value = try! decoder.decode(ValueType.self, from: data)
      aBlock(value)
    }
  }

  /**
   Force the observer to forget its observation reference (something that happens automatically if/when the observer
   is no longer held by another object).
   */
  public func forget() {
    guard let observer = self.observer else { return }
    NotificationCenter.default.removeObserver(observer)
    self.observer = nil
  }

  /**
   Cleanup notification registration by removing our internal observer from notifications.
   */
  deinit {
    forget()
  }
}
