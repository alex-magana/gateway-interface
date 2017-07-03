require 'spec_helper'
require 'support/reader_helper'
require 'json'
require 'csv_reader'

RSpec.describe CsvReader do
  base_spec_fixture_path = File.join(File.dirname(__FILE__), '/fixture')

  let(:payload) do
    JSON.parse(File.read(base_spec_fixture_path + '/out/payload.json',
                         encoding: 'UTF-8'))
  end
  let(:assets_array) do
    JSON.parse(File.read(base_spec_fixture_path + '/out/assets_array',
                         encoding: 'UTF-8'))
  end
  let(:published_assets_path) { 'spec/fixture/in' }
  let(:payload_path) { 'spec/fixture/out' }

  gateway_response = {
    'results' => {
      'assets_status' => 'published'
    }
  }

  subject { described_class.new(published_assets_path) }

  before(:each) do
    allow(subject).to receive(:send_request).and_return(gateway_response)
  end

  describe '#csv_read' do
    it 'indicates the status of the re-publish' do
      expect(subject.csv_read).to eq(gateway_response)
    end
  end

  describe '#file_names' do
    it 'returns an array of files' do
      expect(subject.file_names).to eq(['assets_report.csv'])
    end
  end

  describe '#build_payload' do
    it 'returns an array of assets' do
      payload_with_symbolized_keys = payload.map { |asset| symbolize_keys(asset) }
      expect(subject.build_payload('assets_report.csv')).to eq(payload_with_symbolized_keys)
    end
  end

  describe '#assets' do
    it 'returns a csv table containing asset details' do
      expect(subject.assets('assets_report.csv').class).to eq(CSV::Table)
    end

    it 'returns an array of arrays' do
      expect(subject.assets('assets_report.csv').to_a).to eq(assets_array)
    end
  end

  describe '#site_name' do
    news_uri = '/news/world-europe-40362094'
    zhongwen_simp_uri = '/zhongwen/simp/40198087'

    it 'returns the correct site name for news' do
      expect(subject.site_name(news_uri)).to eq('/news')
    end

    it 'returns the correct site name for zohongwen simp' do
      expect(subject.site_name(zhongwen_simp_uri)).to eq('/zhongwen/simp')
    end
  end

  describe '#submit_assets' do
    it 'returns the status of asset publish/withdraw' do
      assets_by_file = [payload]

      expect(subject.submit_assets(assets_by_file)).to eq(gateway_response)
    end
  end

  describe '#send_request' do

    it 'returns a response given a valid uri' do
      uri = 'https://mockbin.org/bin/d7cc9194-b27e-4d4d-aad3-e664d745f453?foo=bar&foo=baz'
      header = { 'Content-Type' => 'application/json' }
      assets = { :assets => [payload] }

      expect(subject.send_request(uri, header, assets)).to eq(gateway_response)
    end
  end
end
