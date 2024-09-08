import Foundation
import SQLite

private typealias Expression = SQLite.Expression

private struct MigrationDB {
  static let table = Table("schema_migrations")
  static let version = Expression<Int64>("version")
}

/// Interface for managing migrations for a SQLite database accessed via `SQLite.swift`.
public struct SQLiteMigrationManager {
  /// The `SQLite.swift` database `Connection`.
  fileprivate let db: Connection

  /// All migrations discovered by the receiver.
  public let migrations: [Migration]

  /**
   Creates a new migration manager.

   - parameters:
     - db: The database `Connection`.
     - migrations: An array of `Migration`. Defaults to `[]`.
     - bundle: An `NSBundle` containing SQL migrations. Defaults to `nil`.
   */
  public init(db: Connection, migrations: [Migration] = [], bundle: Bundle? = nil) {
    self.db = db
    self.migrations = [
      bundle?.migrations() ?? [],
      migrations
    ].joined().sorted { $0.version < $1.version }
  }

  /**
   Creates a new migration manager.

   - parameters:
     - url: The url to a database with which to initialize the migration manager.
     - migrations: An array of `Migration`. Defaults to `[]`.
     - bundle: An `NSBundle` containing SQL migrations. Defaults to `nil`.
   */
  public init?(url: URL, migrations: [Migration] = [], bundle: Bundle? = nil) {
    do {
      let db = try Connection(url.absoluteString)
      self.init(db: db, migrations: migrations, bundle: bundle)
    } catch {
      return nil
    }
  }

  /**
   Creates a new migration manager.

   - parameters:
     - path: The path to a database with which to initialize the migration manager.
     - migrations: An array of `Migration`. Defaults to `[]`.
     - bundle: An `NSBundle` containing SQL migrations. Defaults to `nil`.
   */
  public init?(path: String, migrations: [Migration] = [], bundle: Bundle? = nil) {
    if let url = URL(string: path) {
      self.init(url: url, migrations: migrations, bundle: bundle)
    }
    return nil
  }

  /**
   Returns a `Bool` value that indicates if the `schema_migrations` table is present in the database managed by the receiver.
   */
  public func hasMigrationsTable() -> Bool {
    let sqliteMaster = Table("sqlite_master")
    let type = Expression<String>("type")
    let name = Expression<String>("name")

    do {
      let tableCount = try db.scalar(sqliteMaster.filter(type == "table" && name == "schema_migrations").count)
      return tableCount == 1
    } catch {
      return false
    }
  }

  /**
   Creates the `schema_migrations` table in the database managed by the receiver.
   */
  public func createMigrationsTable() throws {
    try db.run(MigrationDB.table.create(ifNotExists: true) { table in
      table.column(MigrationDB.version, unique: true)
    })
  }

  /**
   The current version of the database managed by the receiver or `0` if the migrations table is not present or empty.
   */
  public func currentVersion() -> Int64 {
    if !hasMigrationsTable() {
      return 0
    }

    do {
      let version = try db.scalar(MigrationDB.table.select(MigrationDB.version.max))
      return version ?? 0
    } catch {
      return 0
    }
  }

  /**
   The origin version of the database managed by the receiver or `0` if the migrations table is not present or empty.
   */
  public func originVersion() -> Int64 {
    if !hasMigrationsTable() {
      return 0
    }

    do {
      let version = try db.scalar(MigrationDB.table.select(MigrationDB.version.min))
      return version ?? 0
    } catch {
      return 0
    }
  }

  /**
   An array of versions contained in the migrations table managed by the receiver. Empty if the migrations table is not present.
   */
  public func appliedVersions() -> [Int64] {
    do {
      var versions = [Int64]()
      try db.prepare(MigrationDB.table.select(MigrationDB.version).order(MigrationDB.version)).forEach {
        versions.append($0[MigrationDB.version])
      }
      return versions
    } catch {
      return []
    }
  }

  /**
   A subset of `migrations` that have not yet been applied to the database managed by the receiver.
   */
  public func pendingMigrations() -> [Migration] {
    if !hasMigrationsTable() {
      return migrations
    }

    let versions = appliedVersions()
    return migrations.filter { migration in
      !versions.contains(migration.version)
    }
  }

  /**
   Returns a `Bool` value that indicates if the database managed by the receiver is in need of migration.
   */
  public func needsMigration() -> Bool {
    if !hasMigrationsTable() {
      return false
    }

    return pendingMigrations().count > 0
  }

  /**
   Migrates the database managed by the receiver to the specified version.

   Each individual migration is performed within a transaction that is rolled back if any error occurs.

   - parameters:
     - toVersion: The target version to migrate the database to. Defaults to `Int64.max`.
   */
  public func migrateDatabase(toVersion: Int64 = Int64.max) throws {
    try pendingMigrations().filter { $0.version <= toVersion }.forEach { migration in
      try db.transaction {
        try migration.migrateDatabase(self.db)
        let _ = try self.db.run(MigrationDB.table.insert(MigrationDB.version <- migration.version))
      }
    }
  }
}

extension Bundle {
  fileprivate func migrations() -> [Migration] {
    if let urls = urls(forResourcesWithExtension: "sql", subdirectory: nil) {
      return urls.compactMap { item in
        if let nsURL = item as? NSURL {
          return FileMigration(url: nsURL as URL) ?? nil
        } else if let url = item as? URL {
          return FileMigration(url: url)
        } else if let url = URL(string: item.absoluteString) {
          return FileMigration(url: url)
        } else {
          return nil
        }
      }
    } else {
      return []
    }
  }
}

/// The `Migration` protocol is adopted in order to provide migration of SQLite databases accessed via `SQLite.swift`
public protocol Migration: CustomStringConvertible {
  /// The numeric version of the migration.
  var version: Int64 { get }

  /// Tells the receiver to apply its changes to the given database.
  func migrateDatabase(_ db: Connection) throws
}

public extension Migration {
  var description: String {
    return "Migration(\(version))"
  }
}

/// The `FileMigration` struct is used to reference SQL file migrations.
public struct FileMigration: Migration {
  /// The numeric version of the migration.
  public let version: Int64
  /// The `NSURL` of the migration file.
  public let url: URL

  /// Tells the receiver to apply its changes to the given database.
  public func migrateDatabase(_ db: Connection) throws {
    let fileContents = try NSString(contentsOf: url, encoding: String.Encoding.utf8.rawValue)
    try db.execute(fileContents as String)
  }
}

extension FileMigration {
  /**
   Creates a new file migration.

   File migrations should have filenames of the form:
   - `1.sql`
   - `2_add_new_table.sql`
   - `3_add-new-table.sql`
   - `4_add new table.sql`

   - returns: A file migration if the filename matches `^(\d+)_?([\w\s-]*)\.sql$`.
   */
  public init?(url: URL) {
    guard let version = FileMigration.extractVersion(url.lastPathComponent) else {
      return nil
    }

    self.version = version
    self.url = url
  }
}

extension FileMigration {
  static fileprivate let regex = try! NSRegularExpression(pattern: "^(\\d+)_?([\\w\\s-]*)\\.sql$", options: .caseInsensitive)

  static fileprivate func extractVersion(_ filename: String) -> Int64? {
    if let result = regex.firstMatch(in: filename, options: .reportProgress, range: NSMakeRange(0, filename.distance(from: filename.startIndex, to: filename.endIndex))), result.numberOfRanges == 3 {
      return Int64((filename as NSString).substring(with: result.range(at: 1)))
    }
    return nil
  }
}

extension FileMigration: CustomStringConvertible {
  public var description: String {
    return "FileMigration(\(version), \(url))"
  }
}
