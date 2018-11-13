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

  // MARK: hasMigrationsTable

  func test_hasMigrationsTable_noTable() {
    let result = subject.hasMigrationsTable()

    XCTAssertFalse(result, "returns false when there is no migrations table")
  }

  func test_hasMigrationsTable_withTable() {
    createMigrationTable()

    let result = subject.hasMigrationsTable()

    XCTAssertTrue(result, "returns true when there is a migrations table")
  }

  // MARK: createMigrationsTable

  func test_createMigrationsTable_noTable() throws {
    try subject.createMigrationsTable()

    XCTAssertTrue(subject.hasMigrationsTable(), "creates a migrations table")
  }

  func test_createMigrationsTable_withTable() {
    createMigrationTable()

    XCTAssertNoThrow(try subject.createMigrationsTable(), "does not throw if the table already exists")
  }

  // MARK: currentVersion

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

  // MARK: originVersion

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
}
