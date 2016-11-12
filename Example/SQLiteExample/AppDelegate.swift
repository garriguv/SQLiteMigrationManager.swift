import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

    guard let database = Database() else {
      fatalError("could not setup database")
    }

    do {
      try database.migrateIfNeeded()
    } catch {
      fatalError("failed to migrate database: \(error)")
    }

    print(database)

    return true
  }
}
