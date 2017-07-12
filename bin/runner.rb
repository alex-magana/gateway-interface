require 'bundler'
Bundler.require

$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')

require 'csv_reader'

csv_reader = CsvReader.new

ARGV.each do |asset_report_url|
  csv_reader.process_csv(asset_report_url)
end
