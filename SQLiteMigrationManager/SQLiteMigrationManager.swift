import Foundation
import SQLite

public struct SQLiteMigrationManager {
  let db: Connection
  let migrationsBundle: NSBundle

  private let schemaMigrations = Table("schema_migrations")
  private let version = Expression<Int64>("version")

  public init(db: Connection, migrationsBundle: NSBundle) {
    self.db = db
    self.migrationsBundle = migrationsBundle
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

  public func originVersion() -> Int64 {
    if !hasMigrationsTable() {
      return 0
    }

    return db.scalar(schemaMigrations.select(version.min)) ?? 0
  }

  public func migrations() -> [Migration] {
    let regex = try! NSRegularExpression(pattern: "^(\\d+)_([\\w\\s-]+)\\.sql$", options: .CaseInsensitive)

    return migrationsBundle.URLsForResourcesWithExtension("sql", subdirectory: nil)?.filter {
      url in
      if let fileName = url.lastPathComponent,
      let result = regex.firstMatchInString(fileName, options: .ReportProgress, range: NSMakeRange(0, fileName.startIndex.distanceTo(fileName.endIndex))) {
        return result.numberOfRanges == 3
      } else {
        return false
      }
    }.map {
      url in
      let fileName: String = url.lastPathComponent!
      return FileMigration(
        version: Int64(fileName.substringToIndex(fileName.rangeOfString("_", options: .CaseInsensitiveSearch)!.startIndex))!,
        url: url)
    } ?? []
  }
}

public protocol Migration {
  var version: Int64 { get }
}

public struct FileMigration: Migration {
  public let version: Int64
  public let url: NSURL

  public init(version: Int64, url: NSURL) {
    self.version = version
    self.url = url
  }
}

extension FileMigration: CustomStringConvertible {
  public var description: String {
    return "\(version) \(url)"
  }
}
