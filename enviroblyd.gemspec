require_relative "lib/enviroblyd/version"

Gem::Specification.new do |spec|
  spec.name        = "enviroblyd"
  spec.version     = Enviroblyd::VERSION
  spec.authors     = [ "Robert Starsi" ]
  spec.email       = "klevo@klevo.sk"
  spec.homepage    = "https://github.com/envirobly/enviroblyd"
  spec.summary     = "Envirobly instance daemon"
  spec.license     = "MIT"

  spec.files = Dir[ "lib/**/*", "LICENSE" ]
  spec.executables = %w[ enviroblyctl enviroblyd ]

  # spec.add_dependency "activesupport", "~> 7.0"
  spec.add_dependency "thor", "~> 1.3"
  spec.add_dependency "zeitwerk", "~> 2.6"
  # spec.add_dependency "httpx", "~> 1.1"
  # spec.add_dependency "aws-sdk-s3", "~> 1.141"

  spec.add_development_dependency "debug", "~> 1.8"
end
