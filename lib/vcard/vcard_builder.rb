require 'ostruct'

# slurp command line options and build the vcards
class VcardBuilder
  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def parse_options
    options = {
      filename: 'config.yml'
    }
    optparse = OptionParser.new do|opts|
      # Set a banner, displayed at the top of the help screen.
      opts.banner = 'Usage: .build.rb [options] '
      opts.on('-v', '--verbose', 'Output more information') do
        Loggr.allow_info = true
      end
      opts.on('-d', '--debug', 'Output even more information') do
        Loggr.allow_info = true
        Loggr.allow_debug = true
      end
      opts.on('--local', 'Use local cached photos and worksheet') do
        options[:local] = true
      end
      opts.on('--offline', 'Use local cached photos and worksheet') do
        options[:local] = true
      end
      opts.on('-c', '--config FILE', 'config file (default "config.yml")') do |fn|
        options[:filename] = fn
      end

      opts.on('-h', '--help', 'Prints this help') do
        puts opts
        exit
      end
    end
    # parse the command line arguments
    optparse.parse!

    @conf = ConfigReader.new.read_config(options)
    @conf.ensure_required_params
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  def initialize
    @conf = OpenStruct.new

    # options will be added to @conf
    parse_options

    Loggr.info 'Verbose setting selected. Writing extra info'
    Loggr.debug 'Even more verbose setting selected. Writing even more info'
    Loggr.info '--local set. Using cache instead of http requests' if @conf[:local]
  end

  def build
    ws = Worksheeter.new(@conf)
    puts 'Loading worksheet...'
    ws.load_worksheet
    puts 'Generate contacts..'
    contacts = ws.generate_contacts
    puts 'Fetching photos..'
    ws.fetch_photos(contacts)
    puts 'Generating vcards..'
    ws.generate_vcards(contacts)
    ws.build_instructions
    puts 'Writing zip file..'
    ws.zip_folder
    puts 'Done'
  end
end
