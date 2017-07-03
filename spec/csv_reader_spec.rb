require 'spec_helper'
require 'support/reader_helper'
require 'json'
require 'csv_reader'

RSpec.describe CsvReader do
  base_spec_fixture_path = File.join(File.dirname(__FILE__), '/fixture')

  let(:assets_by_file) do
    JSON.parse(File.read(base_spec_fixture_path + '/out/assets_by_file.json',
                         encoding: 'UTF-8'))
  end
  let(:assets) do
    JSON.parse(File.read(base_spec_fixture_path + '/out/assets.json',
                         encoding: 'UTF-8'))
  end
  let(:assets_array) do
    JSON.parse(File.read(base_spec_fixture_path + '/out/assets_array',
                         encoding: 'UTF-8'))
  end
  let(:published_assets_path) { 'spec/fixture/in' }
  let(:assets_path) { 'spec/fixture/out' }

  subject { described_class.new(published_assets_path, 'test') }


  describe '#process_csv' do
    before do
      allow(subject).to receive(:process_csv).and_return(assets_by_file)
    end

    it 'indicates the status of the re-publish' do
      expect(subject.process_csv).to eq(assets_by_file)
    end
  end

  describe '#file_names' do
    it 'returns an array of files' do
      expect(subject.file_names).to eq(['assets_report.csv'])
    end
  end

  describe '#retrieve_asset_details' do
    it 'returns an array of assets' do
      assets_with_symbolized_keys = assets.map { |asset| symbolize_keys(asset) }
      expect(subject.retrieve_asset_details('assets_report.csv')).to eq(assets_with_symbolized_keys)
    end
  end

  describe '#read_file' do
    it 'returns a csv table containing asset details' do
      expect(subject.read_file('assets_report.csv').class).to eq(CSV::Table)
    end

    it 'returns an array of arrays' do
      expect(subject.read_file('assets_report.csv').to_a).to eq(assets_array)
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

  describe '#process_assets_by_file' do
    it 'returns the status of asset publish/withdraw' do
      assets_by_file = [assets]

      expect(subject.process_assets_by_file(assets_by_file)).to eq(assets_by_file)
    end
  end

  describe '#make_request' do
    before do
      allow(subject).to receive(:make_request).and_return(assets_by_file[0][0])
    end

    it 'returns a response given a valid uri' do

      expect(subject.make_request(assets[0])).to eq(assets_by_file[0][0])
    end
  end
end
