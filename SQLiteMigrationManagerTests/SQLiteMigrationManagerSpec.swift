import Quick
import Nimble
import SQLiteMigrationManager
import SQLite

class SQLiteMigrationManagerSpec: QuickSpec {
  override func spec() {
    var subject: SQLiteMigrationManager!

    var db: Connection!

    beforeEach {
      try! db = Connection(.Temporary)
      subject = SQLiteMigrationManager(db)
    }

    describe("hasMigrationsTable()") {
      context("when there is no migration table") {
        it("returns false") {
          expect(subject.hasMigrationsTable()).to(beFalse())
        }
      }

      context("when there is a migration table") {
        beforeEach {
          createMigrationTable(db)
        }

        it("returns true") {
          expect(subject.hasMigrationsTable()).to(beTrue())
        }
      }
    }

    describe("currentVersion()") {
      context("when there is no migration table") {
        it("returns 0") {
          expect(subject.currentVersion()).to(equal(0))
        }
      }

      context("when there is a migration table") {
        beforeEach {
          createMigrationTable(db)
        }

        context("when the migration table is empty") {
          it("returns 0") {
            expect(subject.currentVersion()).to(equal(0))
          }
        }

        context("when the migration table cointains migrations") {
          beforeEach {
            insertMigration(db, version: 1337)
          }

          it("returns the latest migration") {
            expect(subject.currentVersion()).to(equal(1337))
          }
        }
      }
    }
  }
}

private func createMigrationTable(db: Connection) {
  try! db.execute("CREATE TABLE schema_migrations(version INTEGER UNIQUE NOT NULL);")
}

private func insertMigration(db: Connection, version: Int64) {
  let stmt = try! db.prepare("INSERT INTO schema_migrations(version) VALUES (?);")
  try! stmt.run(version)
}
