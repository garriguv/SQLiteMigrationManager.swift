import Foundation
import SQLiteMigrationManager
import SQLite

struct SeedDB: Migration {
  var version: Int64 = 20160119131206685

  func migrateDatabase(db: Connection) throws {
    let episodes = Table("episodes")
    let season = Expression<Int>("season")
    let name = Expression<String>("name")

    try (1...24).map { "Episode \($0)" }.forEach {
      try db.run(episodes.insert(season <- 1, name <- $0))
    }
  }
}
