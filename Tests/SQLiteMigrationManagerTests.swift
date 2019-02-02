import Foundation
import XCTest
@testable import SQLiteMigrationManager
import SQLite


final class SQLiteMigrationManagerTests: XCTestCase {
  private var subject: SQLiteMigrationManager!

  private var db: Connection!
  private var testBundle: Bundle!

  override func setUp() {
    super.setUp()

    db = try! Connection(.temporary)

    subject = SQLiteMigrationManager(db: db)

    testBundle = Bundle(for: type(of: self))
  }

  // MARK: - hasMigrationsTable

  func test_hasMigrationsTable_noTable() {
    let result = subject.hasMigrationsTable()

    XCTAssertFalse(result, "returns false when there is no migrations table")
  }

  func test_hasMigrationsTable_withTable() {
    createMigrationTable()

    let result = subject.hasMigrationsTable()

    XCTAssertTrue(result, "returns true when there is a migrations table")
  }

  // MARK: - createMigrationsTable

  func test_createMigrationsTable_noTable() throws {
    try subject.createMigrationsTable()

    XCTAssertTrue(subject.hasMigrationsTable(), "creates a migrations table")
  }

  func test_createMigrationsTable_withTable() {
    createMigrationTable()

    XCTAssertNoThrow(try subject.createMigrationsTable(), "does not throw if the table already exists")
  }

  // MARK: - currentVersion

  func test_currentVersion_noMigrationsTable() {
    let result = subject.currentVersion()

    XCTAssertEqual(result, 0, "returns 0 when there is no migrations table")
  }

  func test_currentVersion_withTable_empty() {
    createMigrationTable()

    let result = subject.currentVersion()

    XCTAssertEqual(result, 0, "returns 0 when there is an empty migrations table")
  }

  func test_currentVersion_withTable_notEmpty() {
    createMigrationTable()
    insertMigration(version: 2)
    insertMigration(version: 3)
    insertMigration(version: 5)

    let result = subject.currentVersion()

    XCTAssertEqual(result, 5, "returns the latest migration")
  }

  // MARK: - originVersion

  func test_originVersion_noTable() {
    let result = subject.originVersion()

    XCTAssertEqual(result, 0, "returns 0 when there is no migrations table")
  }

  func test_originVersion_withTable_empty() {
    createMigrationTable()

    let result = subject.originVersion()

    XCTAssertEqual(result, 0, "returns 0 when there is an empty migrations table")
  }

  func test_originVersion_withTable_notEmpty() {
    createMigrationTable()
    insertMigration(version: 2)
    insertMigration(version: 3)
    insertMigration(version: 5)

    let result = subject.originVersion()

    XCTAssertEqual(result, 2, "returns the first migration")
  }

  // MARK: - migrations

  func test_migrations_noMigrationsInBundle_withMigrations() throws {
    subject = try makeSubject(migrations: [TestMigration(version: 1), TestMigration(version: 0)], bundleName: "Migrations_empty")

    let result = subject.migrations

    XCTAssertEqual(result.count, 2, "returns an array of migrations")
    XCTAssertEqual(result.map { m in m.version }, [0, 1], "orders the migrations by version ascending")
  }

  func test_migrations_noMigrationsInBundle_withoutMigrations() throws {
    subject = try makeSubject(migrations: [], bundleName: "Migrations_empty")

    let result = subject.migrations

    XCTAssertTrue(result.isEmpty, "returns an empty array")
  }

  func test_migrations_migrationsInBundle_withMigrations() throws {
    subject = try makeSubject(migrations: [TestMigration(version: 0), TestMigration(version: 20160117220050567)], bundleName: "Migrations")

    let result = subject.migrations

    XCTAssertEqual(result.count, 5, "returns an array of migrations")
    XCTAssertEqual(result.map { m in m.version }, [0, 20160117220032473, 20160117220038856, 20160117220050560, 20160117220050567], "orders the migrations by version ascending")
  }

  func test_migrations_migrationsInBundle_withoutMigrations() throws {
    subject = try makeSubject(migrations: [], bundleName: "Migrations")

    let result = subject.migrations

    XCTAssertEqual(result.count, 3, "returns an array of migrations")
    XCTAssertEqual(result.map { m in m.version }, [20160117220032473, 20160117220038856, 20160117220050560], "orders the migrations by version ascending")
  }

  func test_migrations_fileNames() throws {
    subject = try makeSubject(migrations: [], bundleName: "Migrations-names")

    let result = subject.migrations

    XCTAssertEqual(result.count, 4, "returns all migrations")
  }

  // MARK: - appliedVersions

  func test_appliedVersions_noTable() {
    let result = subject.appliedVersions()

    XCTAssertTrue(result.isEmpty, "returns an empty array when there is no migrations table")
  }

  func test_appliedVersions_withTable_empty() {
    createMigrationTable()

    let result = subject.appliedVersions()

    XCTAssertTrue(result.isEmpty, "returns an empty array when there is an empty migrations table")
  }

  func test_appliedVersions_withTable_notEmpty() {
    createMigrationTable()
    insertMigration(version: 2)
    insertMigration(version: 3)
    insertMigration(version: 5)

    let result = subject.appliedVersions()

    XCTAssertEqual(result, [2, 3, 5], "returns an array of applied migration versions")
  }

  // MARK: - pendingMigrations

  func test_pendingMigrations_noTable_noMigrations() throws {
    subject = try makeSubject(migrations: [], bundleName: "Migrations_empty")

    let result = subject.pendingMigrations()

    XCTAssertTrue(result.isEmpty, "retuns an empty array of pending migrations")
  }

  func test_pendingMigrations_noTable_withMigrations() throws {
    subject = try makeSubject(migrations: [TestMigration(version: 20160117220050567), TestMigration(version: 0)], bundleName: "Migrations")

    let result = subject.pendingMigrations()

    XCTAssertEqual(result.map { m in m.version }, [0, 20160117220032473, 20160117220038856, 20160117220050560, 20160117220050567], "retuns an array of pending migrations")
  }

  func test_pendingMigrations_withTable_noMigrations() throws {
    createMigrationTable()
    subject = try makeSubject(migrations: [], bundleName: "Migrations_empty")

    let result = subject.pendingMigrations()

    XCTAssertTrue(result.isEmpty, "retuns an empty array of pending migrations")
  }

  func test_pendingMigrations_withTable_withMigrations() throws {
    createMigrationTable()
    subject = try makeSubject(migrations: [TestMigration(version: 20160117220050567), TestMigration(version: 0)], bundleName: "Migrations")

    let result = subject.pendingMigrations()

    XCTAssertEqual(result.map { m in m.version }, [0, 20160117220032473, 20160117220038856, 20160117220050560, 20160117220050567], "retuns an array of pending migrations")
  }

  func test_pendingMigrations_withTable_withMigrations_withAppliedMigrations() throws {
    createMigrationTable()
    subject = try makeSubject(migrations: [TestMigration(version: 20160117220050567), TestMigration(version: 0)], bundleName: "Migrations")
    insertMigration(version: 0)
    insertMigration(version: 20160117220032473)

    let result = subject.pendingMigrations()

    XCTAssertEqual(result.map { m in m.version }, [20160117220038856, 20160117220050560, 20160117220050567], "retuns an array of pending migrations")
  }

  // MARK: - needsMigration

  func test_needsMigration_noTable() {
    let result = subject.needsMigration()

    XCTAssertFalse(result, "returns false when there is no migrations table")
  }

  func test_needsMigration_withTable_withPendingMigrations() {
    createMigrationTable()
    insertMigration(version: 0)
    subject = makeSubject(migrations: [TestMigration(version: 0), TestMigration(version: 1)])

    let result = subject.needsMigration()

    XCTAssertTrue(result, "returns true when there are pending migrations")
  }

  func test_needsMigration_withTable_noPendingMigrations() {
    createMigrationTable()
    insertMigration(version: 0)
    insertMigration(version: 1)
    subject = makeSubject(migrations: [TestMigration(version: 0), TestMigration(version: 1)])

    let result = subject.needsMigration()

    XCTAssertFalse(result, "returns false when there are no pending migrations")
  }

  // MARK: - migrateDatabase

  func test_migrateDatabase_withPendingMigrations_success() throws {
    createMigrationTable()
    try CreateTable(version: 0).migrateDatabase(db)
    try AddRow(version: 1).migrateDatabase(db)
    let fileMigration = try makeFileMigration("3_add-row")
    subject = makeSubject(migrations: [AddRow(version: 2), fileMigration, AddRow(version: 4)])

    XCTAssertNoThrow(try subject.migrateDatabase(), "successfully migrates database")

    XCTAssertEqual(try db.scalar(TestDB.table.count), 4, "applies the migrations")
    XCTAssertEqual(subject.appliedVersions(), [2, 3, 4], "adds the migrations to the migrations table")
  }

  func test_migrateDatabase_withPendingMigrations_failure() throws {
    createMigrationTable()
    try CreateTable(version: 0).migrateDatabase(db)
    try AddRow(version: 1).migrateDatabase(db)
    subject = makeSubject(migrations: [AddRow(version: 2), Throwing(version: 3), AddRow(version: 4)])

    XCTAssertThrowsError(try subject.migrateDatabase(), "throws an error when migrating")

    XCTAssertEqual(try db.scalar(TestDB.table.count), 2, "rolls back the failed migrations")
    XCTAssertEqual(subject.appliedVersions(), [2], "adds the successfule migration to the migrations table")
  }

  func test_migrateDatabase_withPendingMigrations_toVersion() throws {
    createMigrationTable()
    try CreateTable(version: 0).migrateDatabase(db)
    try AddRow(version: 1).migrateDatabase(db)
    let fileMigration = try makeFileMigration("3_add-row")
    subject = makeSubject(migrations: [AddRow(version: 2), fileMigration, AddRow(version: 4)])

    XCTAssertNoThrow(try subject.migrateDatabase(toVersion: 3), "successfully migrates database")

    XCTAssertEqual(try db.scalar(TestDB.table.count), 3, "applies the migrations up to toVersion")
    XCTAssertEqual(subject.appliedVersions(), [2, 3], "adds the migrations to the migrations table")
  }
}

extension SQLiteMigrationManagerTests {
  private func createMigrationTable(file: StaticString = #file, line: UInt = #line) {
    do {
      try db.execute("CREATE TABLE schema_migrations(version INTEGER UNIQUE NOT NULL);")
    } catch {
      XCTFail("createMigrationTable: \(error)", file: file, line: line)
    }
  }

  private func insertMigration(version: Int64, file: StaticString = #file, line: UInt = #line) {
    do {
      let stmt = try db.prepare("INSERT INTO schema_migrations(version) VALUES (?);")
      try stmt.run(version)
    } catch {
      XCTFail("insertMigration: \(error)", file: file, line: line)
    }
  }

  enum TestError: Error {
    case BundleNotFound(String)
    case MigrationNotFound(String)
  }

  private func makeSubject(migrations: [Migration], bundleName: String, file: StaticString = #file, line: UInt = #line) throws -> SQLiteMigrationManager {
    guard let bundleURL = testBundle.url(forResource: bundleName, withExtension: "bundle"), let bundle = Bundle(url: bundleURL) else {
      XCTFail("bundle not found: \(bundleName)", file: file, line: line)
      throw TestError.BundleNotFound(bundleName)
    }
    return SQLiteMigrationManager(db: db, migrations: migrations, bundle: bundle)
  }

  private func makeSubject(migrations: [Migration]) -> SQLiteMigrationManager {
    return SQLiteMigrationManager(db: db, migrations: migrations)
  }

  private func makeFileMigration(_ fileName: String, file: StaticString = #file, line: UInt = #line) throws -> Migration {
    guard let url = testBundle.url(forResource: fileName, withExtension: "sql"), let fileMigration = FileMigration(url: url) else {
      XCTFail("migration not found: \(fileName)", file: file, line: line)
      throw TestError.MigrationNotFound(fileName)
    }
    return fileMigration
  }
}

struct TestDB {
  static let table = Table("test_table")
  static let column = SQLite.Expression<Int>("key")
}

struct TestMigration: Migration {
  let version: Int64

  func migrateDatabase(_ db: Connection) { }
}

struct CreateTable: Migration {
  let version: Int64

  func migrateDatabase(_ db: Connection) throws {
    try db.run(TestDB.table.create { t in
      t.column(TestDB.column)
    })
  }
}

struct AddRow: Migration {
  let version: Int64

  func migrateDatabase(_ db: Connection) throws {
    let _ = try db.run(TestDB.table.insert(TestDB.column <- Int(version)))
  }
}

struct Throwing: Migration {
  let version: Int64

  func migrateDatabase(_ db: Connection) throws {
    throw Result.error(message: "Test error", code: 0, statement: nil)
  }
}
