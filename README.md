# SQLiteMigrationManager.swift
[![Build](https://github.com/garriguv/SQLiteMigrationManager.swift/actions/workflows/build.yml/badge.svg)](https://github.com/garriguv/SQLiteMigrationManager.swift/actions/workflows/build.yml) [![Version](https://img.shields.io/cocoapods/v/SQLiteMigrationManager.swift.svg?style=flat)](http://cocoapods.org/pods/SQLiteMigrationManager.swift)
[![License](https://img.shields.io/cocoapods/l/SQLiteMigrationManager.swift.svg?style=flat)](http://cocoapods.org/pods/SQLiteMigrationManager.swift)
[![Platform](https://img.shields.io/cocoapods/p/SQLiteMigrationManager.swift.svg?style=flat)](http://cocoapods.org/pods/SQLiteMigrationManager.swift)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

SQLiteMigrationManager.swift is a schema management system for [SQLite.swift](https://github.com/stephencelis/SQLite.swift). It is heavily inspired by [FMDBMigrationManager](https://github.com/layerhq/FMDBMigrationManager).

## Concept

SQLiteMigrationManager.swift works by introducing a `schema_migrations` table into the database:

```sql
CREATE TABLE "schema_migrations" (
  "version" INTEGER NOT NULL UNIQUE
);
```

Each row in `schema_migrations` corresponds to a single migration that has been applied and represents a unique version of the schema. This schema supports any versioning scheme that is based on integers, but it is recommended that you utilize an integer that encodes a timestamp.

## Usage

Have a look at the [example project](https://github.com/garriguv/SQLiteMigrationManager.swift/tree/master/Example).

### Creating the Migrations Table

```swift
let db = try Connection("path/to/store.sqlite")

let manager = SQLiteMigrationManager(db: self.db)

if !manager.hasMigrationsTable() {
  try manager.createMigrationsTable()
}
```

### Creating a SQL File Migrations

Create a migration file in your migration bundle:

```
$ touch "`ruby -e "puts Time.now.strftime('%Y%m%d%H%M%S').to_i"`"_name.sql
```

SQLiteMigrationManager.swift will only recognize filenames of the form `<version>_<name>.sql`. The following filenames are valid:

* `1.sql`
* `2_add_new_table.sql`
* `3_add-new-table.sql`
* `4_add new table.sql`

### Creating a Swift Migration

Swift based migrations can be implemented by conforming to the `Migration` protocol:

```swift
import Foundation
import SQLiteMigrationManager
import SQLite

struct SwiftMigration: Migration {
  var version: Int64 = 2016_01_19_13_12_06

  func migrateDatabase(_ db: Connection) throws {
    // perform the migration here
  }
}
```

### Migrating a Database

```swift
let db = try Connection("path/to/store.sqlite")

let manager = SQLiteMigrationManager(db: self.db, migrations: [ SwiftMigration() ], bundle: NSBundle.mainBundle())

if manager.needsMigration() {
  try manager.migrateDatabase()
}
```

### Inspecting the Schema State

```swift
let db = try Connection("path/to/store.sqlite")

let manager = SQLiteMigrationManager(db: self.db, migrations: [ SwiftMigration() ], bundle: NSBundle.mainBundle())

print("hasMigrationsTable() \(manager.hasMigrationsTable())")
print("currentVersion()     \(manager.currentVersion())")
print("originVersion()      \(manager.originVersion())")
print("appliedVersions()    \(manager.appliedVersions())")
print("pendingMigrations()  \(manager.pendingMigrations())")
print("needsMigration()     \(manager.needsMigration())")
```

## Installation

### Swift Package Manager

SQLiteMigrationManager.swift is availabel through [Swift Package Manager](https://swift.org/package-manager/).
To install it, add the following dependency to your `Package.swift` file:

```swift
.package(url: "https://github.com/garriguv/SQLiteMigrationManager.swift.git", from: "0.8.0")
```

### CocoaPods

SQLiteMigrationManager.swift is available through [CocoaPods](https://cocoapods.org). To install
it, add the following line to your `Podfile`:

```ruby
pod "SQLiteMigrationManager.swift"
```

### Carthage

SQLiteMigrationManager.swift is available through [Carthage](https://github.com/Carthage/Carthage). To install
it, add the following line to your `Cartfile`:

```ruby
github "garriguv/SQLiteMigrationManager.swift"
```

## Contributing

1. Fork it ( https://github.com/garriguv/SQLiteMigrationManager.swift/fork )
2. Install the development dependencies (`bin/setup`)
3. Create your feature branch (`git checkout -b my-new-feature`)
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create a new Pull Request
7. You're awesome! :+1:

## Author

Vincent Garrigues, [vincent.garrigues@gmail.com](mailto:vincent.garrigues@gmail.com)

## License

SQLiteMigrationManager.swift is available under the MIT license. See the LICENSE file for more info.
