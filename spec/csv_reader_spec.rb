require 'spec_helper'
require 'csv_reader'

RSpec.describe CsvReader do
  let(:published_assets_path) { 'spec/fixture' }

  subject { described_class.new(published_assets_path) }

  describe '#csv_read' do

  end

  describe '#file_names' do
    it 'returns an array of files' do
      expect(subject.file_names).to eq(['assets_report.csv'])
    end
  end

  describe '#build_payload' do

  end

  describe '#assets' do

  end

  describe '#site_name' do

  end

  describe '#submit_assets' do

  end

  describe '#send_request' do

  end
end
