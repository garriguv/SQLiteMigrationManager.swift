import Foundation
import SQLite

public struct SQLiteMigrationManager {
  let db: Connection

  private let schemaMigrations = Table("schema_migrations")
  private let version = Expression<Int64>("version")

  public init(_ db: Connection) {
    self.db = db
  }

  public func hasMigrationsTable() -> Bool {
    let sqliteMaster = Table("sqlite_master")
    let type = Expression<String>("type")
    let name = Expression<String>("name")
    let count = db.scalar(sqliteMaster.filter(type == "table" && name == "schema_migrations").count)
    return count == 1;
  }

  public func currentVersion() -> Int64 {
    if !hasMigrationsTable() {
      return 0
    }

    return db.scalar(schemaMigrations.select(version.max)) ?? 0
  }
}
