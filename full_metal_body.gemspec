require_relative "lib/full_metal_body/version"

Gem::Specification.new do |spec|
  spec.name        = "full_metal_body"
  spec.version     = FullMetalBody::VERSION
  spec.authors     = ["Toyoaki Oko"]
  spec.email       = ["chariderpato@gmail.com"]
  spec.homepage    = "https://github.com/hayashima/full_metal_body"
  spec.summary     = "FullMetalBody is an input validation tool for ruby on rails."
  spec.description = "FullMetalBody is an input validation tool for ruby on rails."
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/hayashima/full_metal_body"
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", '< 7.1.0', '>= 6.0.0'
  spec.add_dependency "pg", '~> 1.0'
  spec.add_dependency "bury", '>= 2.0.0'
  spec.add_development_dependency "appraisal"
end
