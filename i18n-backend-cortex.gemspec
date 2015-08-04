$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'i18n/backend/cortex/version'

Gem::Specification.new(I18n::Backend::Cortex::VERSION) do |s|
  s.summary = 'Rails I18n Backend for Cortex with etag-aware background polling and memory+[memcache] caching'
  s.authors = ['Michael Grosser', 'CB Content Enablement Team']
  s.name = 'i18n-backend-cortex'
  s.version = I18n::Backend::Cortex::VERSION
  s.email = ['michael@grosser.it', 'ContentEnablementProductTeam@careerbuilder.com']
  s.homepage = 'https://github.com/cortex-cms'
  s.files = `git ls-files lib`.split('\n')
  s.license = 'MIT'
  s.add_runtime_dependency 'i18n'
  s.add_runtime_dependency 'gem_of_thrones'
  s.add_runtime_dependency 'faraday'
end
