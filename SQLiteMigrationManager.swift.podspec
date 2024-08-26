Pod::Spec.new do |s|
  s.name         = "SQLiteMigrationManager.swift"
  s.version      = "0.8.3"
  s.summary      = "Migration manager for SQLite.swift"
  s.description  = <<-DESC
  Migration manager for SQLite.swift, based on FMDBMigrationManager.
                   DESC
  s.homepage     = "https://github.com/garriguv/SQLiteMigrationManager.swift"
  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.author             = { "Vincent Garrigues" => "vincent@garriguv.io" }
  s.social_media_url   = "https://hachyderm.io/@garriguv"

  s.ios.deployment_target = '12.0'
  s.osx.deployment_target = '10.15'
  s.default_subspec  = 'standard'

  s.swift_versions = '5.0'

  s.module_name  = 'SQLiteMigrationManager'
  s.source       = { :git => "https://github.com/garriguv/SQLiteMigrationManager.swift.git", tag: s.version.to_s, submodules: true }

  s.subspec 'standard' do |ss|
   ss.source_files = "Sources"
   ss.dependency "SQLite.swift", "~> 0.15.3"
  end

  s.subspec 'SQLCipher' do |ss|
   ss.source_files = "Sources"
   ss.dependency "SQLite.swift/SQLCipher", "~> 0.15.3"
  end
end
