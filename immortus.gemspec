$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "immortus/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "immortus"
  s.version     = Immortus::VERSION
  s.authors     = %Q{Jose Duarte}
  s.homepage    = ""
  s.summary     = %Q{Immortus is a background jobs tracking helper}
  s.description = %Q{A rails gem to help tracking your background jobs in your application}
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", ">= 4.0.0"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "guard"
  s.add_development_dependency "guard-minitest"
  s.add_development_dependency "minitest-stub_any_instance"
  s.add_development_dependency "spy"
  s.add_development_dependency "byebug"
  s.add_development_dependency "delayed_job_active_record"
end
