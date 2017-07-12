require 'net/http'
require 'uri'
require 'openssl'
require 'open-uri'
require 'csv'
require 'json'
require 'yaml'
require 'logger'

class CsvReader
  @@logger = Logger.new(
    File.join(File.dirname(__FILE__), '..', 'logs/log.txt').to_s,
    10,
    1048576
  )

  def initialize(path = 'assets', env = 'live')
    @path = File.join(File.dirname(__FILE__), '..', path)
    @gateway_uri = config[env]['gateway']['uri']
  end

  def config
    config_path = File.join(File.dirname(__FILE__), '..', 'config/config.yaml')
    YAML.safe_load(File.open(config_path))
  end

  def process_csv(asset_report_url)
    fetch_asset_report(asset_report_url)
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
    asset_file.each do |asset|
      puts "Processing #{asset[:asset_uri]} #{asset[:site_name]} #{asset[:asset_type]} #{asset[:event_type]}"
      build_url(asset)
    end
  end

  def build_url(asset)
    url = "#{@gateway_uri}?asset_uri=#{asset[:asset_uri]}&site_name=#{asset[:site_name]}&asset_type=#{asset[:asset_type]}&event_type=#{asset[:event_type]}"
    fetch(url)
  end

  def fetch(uri_str, limit = 10)
    raise ArgumentError, 'too many HTTP redirects' if limit.zero?

    url = URI.parse(uri_str)

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Post.new(url)
    request["cache-control"] = 'no-cache'
    request["content-type"] = 'application/json'

    @@logger.info("Accessing: #{uri_str}\n")
    log_response(http.request(request))
  end

  def fetch_asset_report(asset_report_url)
    File.open("#{@path}/asset_report.csv", "wb") do |file|
      file.write open(asset_report_url).read
    end
  end

  def log_response(response)
    case response
    when Net::HTTPSuccess then
      @@logger.info("#{response.read_body}\n")
      response
    when Net::HTTPRedirection then
      location = response['location']
      @@logger.info("Redirected to: #{location}\n")
      fetch(location, limit - 1)
    else
      @@logger.error(response.flatten.join(' '))
    end
  end
end
