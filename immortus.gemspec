$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "immortus/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "immortus"
  s.version     = Immortus::VERSION
  s.authors     = ["Nuno Duarte"]
  s.email       = ["n.duarte@runtime-revolution.com"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of Immortus."
  s.description = "TODO: Description of Immortus."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.2.1"

  s.add_development_dependency "sqlite3"
end
