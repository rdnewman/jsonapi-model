lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'jsonapi/model/version'

Gem::Specification.new do |s|
  s.name        = 'jsonapi-model'.freeze
  s.version     = JSONAPI::Model::VERSION

  s.summary     = 'ActiveModel from deserialized JSON:API'.freeze
  s.description = <<~DESCRIPTION
    Rails ActiveModel from deserialized JSON:API endpoints
  DESCRIPTION

  s.authors     = ['Richard Newman'.freeze]
  s.email       = ['richard@newmanworks.com'.freeze]
  s.homepage    = 'https://rubygems.org/gems/jsonapi-model'.freeze
  s.licenses    = ['MIT'.freeze]

  s.files       = Dir['lib/**/*.rb'.freeze]
  s.extra_rdoc_files = Dir[
                    'LICENSE'.freeze,
                    'README.md'.freeze,
                    'CHANGELOG.md'.freeze
                  ]
  s.require_paths = ['lib'.freeze]

  s.metadata = {
    'rubygems_mfa_required' => 'true',
    'source_code_uri' => 'https://github.com/rdnewman/jsonapi-model',
    'bug_tracker_uri' => 'https://github.com/rdnewman/jsonapi-model/issues',
    'security_uri' => 'https://github.com/rdnewman/jsonapi-model/blob/main/SECURITY.md',
    'changelog_uri' => 'https://github.com/rdnewman/jsonapi-model/blob/main/CHANGELOG.md',
    # 'documentation_uri' => 'https://www.rubydoc.info/gems/jsonapi-model'
  }

  s.required_ruby_version = '>= 2.7.0'

  s.add_runtime_dependency 'activemodel', '>= 6.0', '< 8.0'
  s.add_runtime_dependency 'activesupport', '>= 6.0', '< 8.0'
  s.add_runtime_dependency 'excon', '>= 0.88', '< 1.0'
  s.add_runtime_dependency 'jsonapi-serializer', '~> 2.2'

  s.add_development_dependency 'bundler', '~> 2.2'
end
