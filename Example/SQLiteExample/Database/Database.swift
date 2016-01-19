import Foundation
import SQLite
import SQLiteMigrationManager

struct Database {
  let db: Connection
  let migrationManager: SQLiteMigrationManager

  init?() {
    do {
      self.db = try Connection(Database.storeURL().absoluteString)
    } catch {
      return nil
    }

    self.migrationManager = SQLiteMigrationManager(db: self.db, migrations: Database.migrations(), bundle: Database.migrationsBundle())
  }

  func migrateIfNeeded() throws {
    if !migrationManager.hasMigrationsTable() {
      try migrationManager.createMigrationsTable()
    }

    if migrationManager.needsMigration() {
      try migrationManager.migrateDatabase()
    }
  }
}

extension Database {
  static func storeURL() -> NSURL {
    guard let documentsURL = NSURL(string: NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]) else {
      fatalError("could not get user documents directory URL")
    }

    return documentsURL.URLByAppendingPathComponent("store.sqlite")
  }

  static func migrations() -> [Migration] {
    return [ SeedDB() ]
  }

  static func migrationsBundle() -> NSBundle {
    guard let bundleURL = NSBundle.mainBundle().URLForResource("Migrations", withExtension: "bundle") else {
      fatalError("could not find migrations bundle")
    }
    guard let bundle = NSBundle(URL: bundleURL) else {
      fatalError("could not load migrations bundle")
    }

    return bundle
  }
}

extension Database: CustomStringConvertible {
  var description: String {
    return "Database:\n" +
    "url: \(Database.storeURL().absoluteString)\n" +
    "migration state:\n" +
    "  hasMigrationsTable() \(migrationManager.hasMigrationsTable())\n" +
    "  currentVersion()     \(migrationManager.currentVersion())\n" +
    "  originVersion()      \(migrationManager.originVersion())\n" +
    "  appliedVersions()    \(migrationManager.appliedVersions())\n" +
    "  pendingMigrations()  \(migrationManager.pendingMigrations())\n" +
    "  needsMigration()     \(migrationManager.needsMigration())"
  }
}
