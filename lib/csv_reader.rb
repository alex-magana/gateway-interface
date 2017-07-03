require 'csv'
require 'json'
require 'net/http'
require 'uri'
require 'yaml'

class CsvReader
  def initialize(path = 'assets')
    @path = File.join(File.dirname(__FILE__), '..', path)
    @gateway_uri = config['gateway']['uri']
  end

  def csv_read
    assets_by_file = []
    file_names.each do |file_name|
      assets_by_file.push(build_payload(file_name))
    end
    submit_assets(assets_by_file)
  end

  def config
    config_path = File.join(File.dirname(__FILE__), '..', 'config/config.yaml')
    YAML.safe_load(File.open(config_path))
  end

  def file_names
    Dir.chdir(@path) { Dir.glob('*.csv') }
  end

  def build_payload(file_name)
    payload = []
    assets(file_name).each do |asset|
      payload_details = {}
      payload_details[:asset_uri] = asset['asset_uri']
      payload_details[:site_name] = site_name(asset['asset_uri'])
      payload_details[:asset_type] = asset['asset_type']
      payload_details[:event_type] = asset['event_type']
      payload.push(payload_details)
    end

    payload
  end

  def assets(file_name)
    CSV.read("#{@path}/#{file_name}", headers: true)
  end

  def site_name(asset_uri)
    asset_uri[0, asset_uri.rindex('/')]
  end

  def submit_assets(assets_by_file)
    uri = URI.parse(@gateway_uri)
    header = { 'Content-Type' => 'application/json' }
    assets = { :assets => assets_by_file }
    send_request(uri, header, assets)
  end

  def send_request(uri, header, payload)
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.request_uri, header)
    request.body = payload.to_json

    http.request(request)
  end
end
