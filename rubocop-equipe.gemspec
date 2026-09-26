Gem::Specification.new do |spec|
  spec.name     = "rubocop-equipe"
  spec.version  = "0.1.0"
  spec.authors  = ["Jon Stenqvist"]
  spec.email    = ["jon.stenqvist@equipe.com"]

  spec.summary  = "Shared RuboCop configuration for Equipe's Ruby projects"
  spec.homepage = "https://github.com/equipe/rubocop-equipe"

  spec.files    = ["rubocop.yml", "README.md"]

  spec.required_ruby_version = ">= 3.2"

  spec.add_dependency "rubocop-rails-omakase", ">= 1.1"
end
