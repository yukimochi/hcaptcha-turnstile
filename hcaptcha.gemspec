# frozen_string_literal: true

require "./lib/hcaptcha/version"

Gem::Specification.new do |s|
  s.name        = "hcaptcha"
  s.version     = Hcaptcha::VERSION
  s.authors     = ["Christopher Harrison"]
  s.email       = ["chris.harrison@nexusmods.com"]
  s.homepage    = "https://github.com/Nexus-Mods/hcaptcha"
  s.summary     = s.description = "Ruby helpers for hCaptcha"
  s.license     = "MIT"
  s.required_ruby_version = '>= 2.3.0'

  s.files       = `git ls-files lib rails README.md CHANGELOG.md LICENSE`.split("\n")

  s.add_runtime_dependency "json"
  s.add_development_dependency "mocha"
  s.add_development_dependency "rake"
  s.add_development_dependency "i18n"
  s.add_development_dependency "maxitest"
  s.add_development_dependency "pry-byebug"
  s.add_development_dependency "bump"
  s.add_development_dependency "webmock"
  s.add_development_dependency "rubocop"

  s.metadata = { "source_code_uri" => "https://github.com/Nexus-Mods/hcaptcha" }
end
