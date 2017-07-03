require 'bundler'
Bundler.require

$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')

require 'csv_reader'

CsvReader.new.process_csv
