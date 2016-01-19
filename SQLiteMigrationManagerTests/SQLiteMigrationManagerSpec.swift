import Quick
import Nimble
import SQLiteMigrationManager
import SQLite

struct SomeMigration: Migration {
  let version: Int64 = 20160117220032475

  func migrateDatabase(db: Connection) { }
}

struct SomeOtherMigration: Migration {
  let version: Int64 = 20160117220050567

  func migrateDatabase(db: Connection) { }
}

struct TestDB {
  static let table = Table("test_table")
  static let column = SQLite.Expression<Int>("key")
}

struct CreateTable: Migration {
  let version: Int64

  func migrateDatabase(db: Connection) throws {
    try db.run(TestDB.table.create { t in
      t.column(TestDB.column)
    })
  }
}

struct AddRow: Migration {
  let version: Int64

  func migrateDatabase(db: Connection) throws {
    try db.run(TestDB.table.insert(TestDB.column <- Int(version)))
  }
}

struct Throwing: Migration {
  let version: Int64

  func migrateDatabase(db: Connection) throws {
    throw Result.Error(message: "Test error", code: 0, statement: nil)
  }
}

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

    describe("createMigrationsTable()") {
      context("when there is no migrations table") {
        it("creates a migration table") {
          try! subject.createMigrationsTable()

          expect(subject.hasMigrationsTable()).to(beTrue())
        }
      }

      context("when there is already a migrations table") {
        beforeEach {
          createMigrationTable(db)
        }

        it("does not throw") {
          expect { try subject.createMigrationsTable() }.notTo(throwError())
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
        var bundleURL: NSURL!

        beforeEach {
          bundleURL = testBundle.URLForResource("Migrations_empty", withExtension: "bundle")!
        }

        context("when migrations are supplied") {
          beforeEach {
            let migrations: [Migration] = [ SomeMigration(), SomeOtherMigration() ]
            subject = SQLiteMigrationManager(db: db, migrations: migrations, migrationsBundle: NSBundle(URL: bundleURL)!)
          }

          it("returns an array of migrations") {
            expect(subject.migrations()).to(haveCount(2))
          }

          it("returns an ordered array of migrations") {
            expect(subject.migrations()[0].version).to(equal(20160117220032475))
            expect(subject.migrations()[1].version).to(equal(20160117220050567))
          }
        }

        context("when migrations are not supplied") {
          beforeEach {
            subject = SQLiteMigrationManager(db: db, migrations: [], migrationsBundle: NSBundle(URL: bundleURL)!)
          }

          it("returns an empty array") {
            expect(subject.migrations()).to(beEmpty())
          }
        }
      }

      context("when there are migrations in the bundle") {
        var bundleURL: NSURL!

        beforeEach {
          bundleURL = testBundle.URLForResource("Migrations", withExtension: "bundle")!
        }

        context("when migrations are supplied") {
          beforeEach {
            let migrations: [Migration] = [ SomeMigration(), SomeOtherMigration() ]
            subject = SQLiteMigrationManager(db: db, migrations: migrations, migrationsBundle: NSBundle(URL: bundleURL)!)
          }

          it("returns an array of migrations") {
            expect(subject.migrations()).to(haveCount(5))
          }

          it("returns an ordered array of migrations") {
            expect(subject.migrations()[0].version).to(equal(20160117220032473))
            expect(subject.migrations()[4].version).to(equal(20160117220050567))
          }
        }

        context("when migrations are not supplied") {
          beforeEach {
            subject = SQLiteMigrationManager(db: db, migrations: [], migrationsBundle: NSBundle(URL: bundleURL)!)
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

    describe("appliedVersions()") {
      context("when there is no migration table") {
        it("returns an empty array") {
          expect(subject.appliedVersions()).to(beEmpty())
        }
      }

      context("when there is a migration table") {
        beforeEach {
          createMigrationTable(db)
        }

        context("when the migration table is empty") {
          it("returns an empty array") {
            expect(subject.appliedVersions()).to(beEmpty())
          }
        }

        context("when the migration table contains migrations") {
          beforeEach {
            insertMigration(db, version: 2)
            insertMigration(db, version: 3)
            insertMigration(db, version: 5)
          }

          it("returns an array of versions") {
            expect(subject.appliedVersions()).to(equal([2, 3, 5]))
          }
        }
      }
    }

    describe("pendingMigrations()") {
      context("when there is no migration table") {
        context("when there are no migrations") {
          beforeEach {
            let bundleURL = testBundle.URLForResource("Migrations_empty", withExtension: "bundle")!
            subject = SQLiteMigrationManager(db: db, migrationsBundle: NSBundle(URL: bundleURL)!)
          }

          it("returns an empty array") {
            expect(subject.pendingMigrations()).to(beEmpty())
          }
        }

        context("when there are migrations") {
          beforeEach {
            let bundleURL = testBundle.URLForResource("Migrations", withExtension: "bundle")!
            let migrations: [Migration] = [ SomeMigration(), SomeOtherMigration() ]
            subject = SQLiteMigrationManager(db: db, migrations: migrations, migrationsBundle: NSBundle(URL: bundleURL)!)
          }

          it("returns an array of versions") {
            expect(subject.pendingMigrations().map {$0.version})
              .to(equal([20160117220032473, 20160117220032475, 20160117220038856, 20160117220050560, 20160117220050567]))
          }
        }
      }

      context("when there is a migration table") {
        beforeEach {
          createMigrationTable(db)
        }

        context("when there are no migrations") {
          beforeEach {
            let bundleURL = testBundle.URLForResource("Migrations_empty", withExtension: "bundle")!
            subject = SQLiteMigrationManager(db: db, migrationsBundle: NSBundle(URL: bundleURL)!)
          }

          it("returns an empty array") {
            expect(subject.pendingMigrations()).to(beEmpty())
          }
        }

        context("when there are migrations") {
          beforeEach {
            let bundleURL = testBundle.URLForResource("Migrations", withExtension: "bundle")!
            let migrations: [Migration] = [ SomeMigration(), SomeOtherMigration() ]
            subject = SQLiteMigrationManager(db: db, migrations: migrations, migrationsBundle: NSBundle(URL: bundleURL)!)
          }

          context("when the migration table is empty") {
            it("returns an array of versions") {
              expect(subject.pendingMigrations().map {$0.version})
                .to(equal([20160117220032473, 20160117220032475, 20160117220038856, 20160117220050560, 20160117220050567]))
            }
          }

          context("when the migration table contains migrations") {
            beforeEach {
              insertMigration(db, version: 20160117220032473)
              insertMigration(db, version: 20160117220032475)
            }

            it("returns an array of versions") {
              expect(subject.pendingMigrations().map {$0.version}).to(equal([20160117220038856, 20160117220050560, 20160117220050567]))
            }
          }
        }
      }
    }

    describe("needsMigration()") {
      context("when there is a migration table") {
        beforeEach {
          createMigrationTable(db)
        }

        context("when there are pending migrations") {
          beforeEach {
            insertMigration(db, version: 20160117220032475)

            let migrations: [Migration] = [ SomeMigration(), SomeOtherMigration() ]
            subject = SQLiteMigrationManager(db: db, migrations: migrations)
          }

          it("returns true") {
            expect(subject.needsMigration()).to(beTrue())
          }
        }

        context("when there are no pending migrations") {
          beforeEach {
            insertMigration(db, version: 20160117220032475)
            insertMigration(db, version: 20160117220050567)

            let migrations: [Migration] = [ SomeMigration(), SomeOtherMigration() ]
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
              AddRow(version: 3),
              AddRow(version: 4)
            ]

            subject = SQLiteMigrationManager(db: db, migrations: migrations)
          }

          it("performs the migration") {
            try! subject.migrateDatabase(toVersion: 3)

            expect(db.scalar(TestDB.table.count)).to(equal(3))
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

            expect(db.scalar(TestDB.table.count)).to(equal(2))
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

private func createMigrationTable(db: Connection) {
  try! db.execute("CREATE TABLE schema_migrations(version INTEGER UNIQUE NOT NULL);")
}

private func insertMigration(db: Connection, version: Int64) {
  let stmt = try! db.prepare("INSERT INTO schema_migrations(version) VALUES (?);")
  try! stmt.run(version)
}
