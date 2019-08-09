import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        setupUI()

        return true
    }

    // MARK: UI

    private func setupUI() {
        self.window?.tintColor = .tintColor
    }
}
