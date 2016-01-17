import Quick
import Nimble
import SQLiteMigrationManager
import SQLite

class SQLiteMigrationManagerSpec: QuickSpec {
  override func spec() {
    var subject: SQLiteMigrationManager!

    var db: Connection!

    var testBundle: NSBundle!

    beforeEach {
      try! db = Connection(.Temporary)

      subject = SQLiteMigrationManager(db: db, migrationsBundle: NSBundle())

      testBundle = NSBundle(forClass: self.dynamicType)
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
            insertMigration(db, version: 2)
            insertMigration(db, version: 3)
            insertMigration(db, version: 5)
          }

          it("returns the latest migration") {
            expect(subject.currentVersion()).to(equal(5))
          }
        }
      }
    }

    describe("originVersion()") {
      context("when there is no migration table") {
        it("returns 0") {
          expect(subject.originVersion()).to(equal(0))
        }
      }

      context("when there is a migration table") {
        beforeEach {
          createMigrationTable(db)
        }

        context("when the migration table is empty") {
          it("returns 0") {
            expect(subject.originVersion()).to(equal(0))
          }
        }

        context("when the migration table cointains migrations") {
          beforeEach {
            insertMigration(db, version: 2)
            insertMigration(db, version: 3)
            insertMigration(db, version: 5)
          }

          it("returns the first migration") {
            expect(subject.originVersion()).to(equal(2))
          }
        }
      }
    }

    describe("migrations()") {
      context("when there are no migrations in the bundle") {
        beforeEach {
          let bundleURL = testBundle.URLForResource("Migrations_empty", withExtension: "bundle")!
          subject = SQLiteMigrationManager(db: db, migrationsBundle: NSBundle(URL: bundleURL)!)
        }

        it("returns an empty array") {
          expect(subject.migrations()).to(beEmpty())
        }
      }

      context("when there are migrations in the bundle") {
        beforeEach {
          let bundleURL = testBundle.URLForResource("Migrations", withExtension: "bundle")!
          subject = SQLiteMigrationManager(db: db, migrationsBundle: NSBundle(URL: bundleURL)!)
        }

        it("returns an array of migrations") {
          expect(subject.migrations()).to(haveCount(3))
        }

        it("returns an ordered array of migrations") {
          expect(subject.migrations()[0].version).to(equal(20160117220032473))
          expect(subject.migrations()[2].version).to(equal(20160117220050560))
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
