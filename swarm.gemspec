# swarm.gemspec
Gem::Specification.new do |s|
  s.name = "swarm"
  s.version = "0.1.0"
  s.summary = "Swarm: A Ruby gem for AI agent interactions"
  s.description = "A Ruby implementation of the Swarm library for managing AI agent interactions"
  s.authors = ["Landon gray"]
  s.email = "landon.gray@hey.com"
  s.homepage = "https://rubygems.org/gems/swarm-rb"
  s.license = "MIT"

  s.files = Dir["lib/**/*", "README.md", "LICENSE"]

  s.add_dependency "ruby-openai", "~> 5.2"
  s.add_dependency "dry-struct", "~> 1.6"
  s.add_dependency "colorize", "~> 0.8"
  s.add_dependency "dotenv"

  s.add_development_dependency "minitest", "~> 5.0"
  s.add_development_dependency "rake", "~> 13.0"
end
