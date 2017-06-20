# Start prompt
# Write command that takes the file name of the csv file
# Check if csv file exists and retrieve it
# Read each row and build payload
# Send payload hash to api gateway

require 'csv'

class CsvReader
  def inititalize(path = './assets')
    @path = path
  end

  def call
    while true
      print PROMPT
      user_input = gets.chomp.strip.downcase
      break if user_input == 'exit'
      command_execute(user_input)
    end
  end

  def command_execute(command_name)
    send((COMMANDS[command_name]).to_s)
  end

  def files
    Dir.chdir(@path) do
      Dir.glob('*.csv')
    end
  end

  def csv_read
    payloads_by_file = []
    payloads_by_file.push(files.each { |file| make_payload(file) })
  end

  def make_payload(file)
    payload = []

    assets = CSV.read(file, headers: true)
    assets.each do |row|
      payload_details = {}
      payload_details[:asset_uri] = row['asset_uri']
      payload_details[:site_name] = site_name(row['asset_uri'])
      payload_details[:asset_type] = row['asset_type']
      payload_details[:event_type] = row['event_type']
      payload.push(payload_details)
    end

    payload
  end
end
