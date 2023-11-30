import SwiftUI
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    self.window = (scene as? UIWindowScene).map { UIWindow(windowScene: $0) }
    self.window?.rootViewController = UINavigationController(
      rootViewController: EnsembleViewController())
    self.window?.makeKeyAndVisible()
  }
}
