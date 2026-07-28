require 'yaml'
require 'date'  # Add this line at the top of the file

# Read the list of audio files
audio_files = Dir.glob('emisije/gozba-*.mp3')

# Create the _shows directory if it doesn't exist
Dir.mkdir('_shows') unless Dir.exist?('_shows')

audio_files.each do |audio_file|
  # Extract date from filename
  date = File.basename(audio_file, '.mp3').split('-')[1..-1].join('-')
  parsed_date = Date.parse(date)

  # Create a new markdown file for each show
  File.open("_shows/#{date}.md", 'w') do |file|
    file.puts "---"
    file.puts "layout: show"
    file.puts "title: Emisija od #{parsed_date.strftime('%d. %m. %Y.')}"
    file.puts "date: #{date}"
    file.puts "audio_path: /#{audio_file}"
    file.puts "---"
  end
end

