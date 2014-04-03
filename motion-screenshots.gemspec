# -*- encoding: utf-8 -*-

Gem::Specification.new do |spec|
  spec.name          = "motion-screenshots"
  spec.version       = "0.0.6"
  spec.authors       = ["Clay Allsopp"]
  spec.email         = ["clay@usepropeller.com"]
  spec.description   = "Take screenshots with RubyMotion"
  spec.summary       = "Take screenshots with RubyMotion"
  spec.homepage      = "https://github.com/usepropeller/motion-screenshots"
  spec.license       = "MIT"

  files = []
  files << 'README.md'
  files.concat(Dir.glob('lib/**/*.rb'))
  files << 'motion-screenshots.gemspec'
  spec.files         = files
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "motion-cocoapods", "~> 1.4.0"

  spec.add_development_dependency "rake"
end
