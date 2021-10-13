Pod::Spec.new do |s|
  s.name         = "SQLiteMigrationManager.swift"
  s.version      = "0.7.0"
  s.summary      = "Migration manager for SQLite.swift"
  s.description  = <<-DESC
  Migration manager for SQLite.swift, based on FMDBMigrationManager.
                   DESC
  s.homepage     = "https://github.com/garriguv/SQLiteMigrationManager.swift"
  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.author             = { "Vincent Garrigues" => "vincent.garrigues@gmail.com" }
  s.social_media_url   = "http://twitter.com/garriguv"

  s.ios.deployment_target = '9.0'
  s.osx.deployment_target = '10.10'

  s.module_name  = 'SQLiteMigrationManager'

  s.source       = { :git => "https://github.com/garriguv/SQLiteMigrationManager.swift.git", tag: s.version.to_s, submodules: true }
  s.source_files = "Sources"

  s.dependency "SQLite.swift", "~> 0.12.2"
end
