require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

require 'webmock/rspec'
require_relative '../lib/i18n/backend/jargon'
Dir["./spec/**/*.rb"].each { |f| require f }

WebMock.allow_net_connect!
