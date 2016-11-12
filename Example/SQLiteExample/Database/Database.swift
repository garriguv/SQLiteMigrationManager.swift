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
  static func storeURL() -> URL {
    guard let documentsURL = URL(string: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]) else {
      fatalError("could not get user documents directory URL")
    }

    return documentsURL.appendingPathComponent("store.sqlite")
  }

  static func migrations() -> [Migration] {
    return [ SeedDB() ]
  }

  static func migrationsBundle() -> Bundle {
    guard let bundleURL = Bundle.main.url(forResource: "Migrations", withExtension: "bundle") else {
      fatalError("could not find migrations bundle")
    }
    guard let bundle = Bundle(url: bundleURL) else {
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
