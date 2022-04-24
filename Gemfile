source 'https://rubygems.org'
gemspec

group :development do
  gem 'rubocop', require: false
  gem 'rubocop-gitlab-security', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rspec', require: false

  gem 'yard', require: false
end

group :test do
  # gem 'codeclimate-test-reporter', require: nil
  gem 'rspec-rails'

  # gem 'factory_bot_rails'

  gem 'jsonapi-rspec'

  gem 'ruby-prof'
  gem 'simplecov', require: false
end

group :development, :test do
  gem 'rails', '< 7.0'
  # gem 'rake' # for travis-ci

  gem 'faker'
end
