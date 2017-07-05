require 'csv'
require 'json'
require 'net/http'
require 'uri'
require 'openssl'
require 'yaml'

class CsvReader
  def initialize(path = 'assets', env = 'live')
    @path = File.join(File.dirname(__FILE__), '..', path)
    @gateway_uri = config[env]['gateway']['uri']
  end

  def config
    config_path = File.join(File.dirname(__FILE__), '..', 'config/config.yaml')
    YAML.safe_load(File.open(config_path))
  end

  def process_csv
    assets_by_file = []
    file_names.each do |file_name|
      assets_by_file.push(retrieve_asset_details(file_name))
    end

    process_assets_by_file(assets_by_file)
  end

  def file_names
    Dir.chdir(@path) { Dir.glob('*.csv') }
  end

  def retrieve_asset_details(file_name)
    assets = []
    read_file(file_name).each do |row|
      asset = {}
      asset[:asset_uri] = row['asset_uri']
      asset[:site_name] = site_name(row['asset_uri'])
      asset[:asset_type] = (row['asset_type']).upcase
      asset[:event_type] = (row['event_type']).upcase
      assets.push(asset)
    end

    assets
  end

  def read_file(file_name)
    CSV.read("#{@path}/#{file_name}", headers: true)
  end

  def site_name(asset_uri)
    asset_uri[0, asset_uri.rindex('/')]
  end

  def process_assets_by_file(assets_by_file)
    assets_by_file.each { |asset_file| submit_asset_details(asset_file) }
  end

  def submit_asset_details(asset_file)
    asset_file.each { |asset| make_request(asset) }
  end

  def make_request(asset)
    fetch("#{@gateway_uri}?asset_uri=#{asset[:asset_uri]}&site_name=#{asset[:site_name]}&asset_type=#{asset[:asset_type]}&event_type=#{asset[:event_type]}")
  end

  def fetch(uri_str, limit = 10)
    raise ArgumentError, 'too many HTTP redirects' if limit == 0

    url = URI.parse(uri_str)

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Post.new(url)
    request["cache-control"] = 'no-cache'
    request["postman-token"] = 'b2aa3a50-8578-24f0-3095-658664198236'
    request["content-type"] = "application/json"

    puts "Accessing: #{uri_str}\n"

    response = http.request(request)
    puts response.read_body

    case response
    when Net::HTTPSuccess then
      response
    when Net::HTTPRedirection then
      location = response['location']
      puts "Redirected to: #{location}\n"
      fetch(location, limit - 1)
    else
      puts "#{response.code} #{response.value}"
    end
  end
end
