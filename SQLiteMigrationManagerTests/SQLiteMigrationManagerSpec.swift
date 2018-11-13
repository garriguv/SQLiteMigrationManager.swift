import Quick
import Nimble
import SQLiteMigrationManager
import SQLite

struct TestMigration: Migration {
  let version: Int64

  func migrateDatabase(_ db: Connection) { }
}

struct TestDB {
  static let table = Table("test_table")
  static let column = SQLite.Expression<Int>("key")
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

class SQLiteMigrationManagerSpec: QuickSpec {
  override func spec() {
    var subject: SQLiteMigrationManager!

    var db: Connection!

    var testBundle: Bundle!

    beforeEach {
      try! db = Connection(.temporary)

      subject = SQLiteMigrationManager(db: db)

      testBundle = Bundle(for: type(of: self))
    }

    describe("needsMigration()") {
      context("when there is a migration table") {
        beforeEach {
          createMigrationTable(db)
        }

        context("when there are pending migrations") {
          beforeEach {
            insertMigration(db, version: 0)

            let migrations: [Migration] = [ TestMigration(version: 0), TestMigration(version: 1) ]
            subject = SQLiteMigrationManager(db: db, migrations: migrations)
          }

          it("returns true") {
            expect(subject.needsMigration()).to(beTrue())
          }
        }

        context("when there are no pending migrations") {
          beforeEach {
            insertMigration(db, version: 0)
            insertMigration(db, version: 1)

            let migrations: [Migration] = [ TestMigration(version: 0), TestMigration(version: 1) ]
            subject = SQLiteMigrationManager(db: db, migrations: migrations)
          }

          it("returns false") {
            expect(subject.needsMigration()).to(beFalse())
          }
        }
      }

      context("when there is NO migration table") {
        it("returns false") {
          expect(subject.needsMigration()).to(beFalse())
        }
      }
    }

    describe("migrateDatabase(toVersion:)") {
      beforeEach {
        createMigrationTable(db)
      }

      context("when there are pending migrations") {
        var migrations: [Migration]!

        beforeEach {
          try! CreateTable(version: 0).migrateDatabase(db)
          try! AddRow(version: 1).migrateDatabase(db)
        }

        context("when the migrations are successful") {
          beforeEach {
            migrations = [
              AddRow(version: 2),
              FileMigration(url: testBundle.url(forResource: "3_add-row", withExtension: "sql")!)!,
              AddRow(version: 4)
            ]

            subject = SQLiteMigrationManager(db: db, migrations: migrations)
          }

          it("performs the migration") {
            try! subject.migrateDatabase(toVersion: 3)

            expect(try! db.scalar(TestDB.table.count)).to(equal(3))
          }

          it("adds the migrations to the migrations table") {
            try! subject.migrateDatabase(toVersion: 3)

            expect(subject.appliedVersions()).to(equal([2, 3]))
          }
        }

        context("when one of the migrations fails") {
          beforeEach {
            migrations = [
              AddRow(version: 2),
              Throwing(version: 3),
              AddRow(version: 4)
            ]

            subject = SQLiteMigrationManager(db: db, migrations: migrations)
          }

          it("throws") {
            expect { try subject.migrateDatabase() }.to(throwError())
          }

          it("rolls back the database") {
            do {
              try subject.migrateDatabase()
            } catch { }

            expect(try! db.scalar(TestDB.table.count)).to(equal(2))
          }

          it("adds the migrations to the migrations table") {
            do {
              try subject.migrateDatabase()
            } catch { }

            expect(subject.appliedVersions()).to(equal([2]))
          }
        }
      }
    }
  }
}

private func createMigrationTable(_ db: Connection) {
  try! db.execute("CREATE TABLE schema_migrations(version INTEGER UNIQUE NOT NULL);")
}

private func insertMigration(_ db: Connection, version: Int64) {
  let stmt = try! db.prepare("INSERT INTO schema_migrations(version) VALUES (?);")
  try! stmt.run(version)
}
