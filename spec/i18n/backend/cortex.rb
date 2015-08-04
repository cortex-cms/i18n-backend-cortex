require_relative '../../spec_helper'

RSpec.describe 'I18n::Backend::Cortex' do

  let(:backend) { I18n::Backend::Cortex.new({host: 'http://www.example.com', uuid: 'Test'})}
  before(:each) do
    stub_request(:get, 'www.example.com/api/v1/uuid/Test').to_return(body: File.new('./spec/support/uuid.json'), status: 200)
    stub_request(:get, 'www.example.com/api/v1/uuid/Test/locales').to_return(body: File.new('./spec/support/locales.json'), status: 200)
    stub_request(:get, 'www.example.com/api/v1/uuid/Test/en').to_return(body: File.new('./spec/support/en.json'), status: 200)
    stub_request(:get, 'www.example.com/api/v1/uuid/Test/sp').to_return(body: File.new('./spec/support/sp.json'), status: 200)
  end

  describe '.available_locales' do
    subject { backend.available_locales }
    it { is_expected.to contain_exactly('en', 'sp')}
    it 'should initialize translations' do
      subject
      expect(backend.initialized?).to be_truthy
    end
  end

  describe '.localization_path' do
    subject { backend.localization_path }
    it { is_expected.to eq 'api/v1/uuid/Test' }
  end

  describe '.locale_path' do
    subject { backend.locale_path('en') }
    it { is_expected.to eq 'api/v1/uuid/Test/en' }
  end

  describe '.translate' do
    it 'returns hello in en' do
      expect(backend.translate('en', 'hello')).to eq 'Hello'
    end
    it 'returns hola in sp' do
      expect(backend.translate('sp', 'hello')).to eq 'Hola'
    end
  end
end
