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

    describe("hasMigrationsTable") {
      context("when there is no migration table") {
        it("returns false") {
          expect(subject.hasMigrationsTable()).to(beFalse())
        }
      }

      context("when there is a migration table") {
        beforeEach {
          try! db.execute("CREATE TABLE schema_migrations(version INTEGER UNIQUE NOT NULL);")
        }

        it("returns true") {
          expect(subject.hasMigrationsTable()).to(beTrue())
        }
      }
    }
  }
}
