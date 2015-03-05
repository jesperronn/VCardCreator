#!/usr/bin/env ruby
# encoding: UTF-8
require 'rubygems'
require 'google_spreadsheet'
require 'fileutils'
require 'digest/md5'
require 'erb'
require 'yaml'
require 'pp'
require 'pry'
require 'i18n'
require 'optparse'

# load files in ./lib
Dir[__dir__ + '/lib/*.rb'].each do |f|
  filename = f.sub(__dir__, '.')
  require_relative filename
end

# Configuration class takes care of all config
class Conf
  Logger.info 'Loading config from file'
  attr_accessor :columns, :start_row, :worksheet, :resigned_contacts,
                :zip_file_name, :conf, :local

  def initialize
    # columns for this spreadsheet (1-index) OR you can use letters :A-:Z
    @columns  = {
      first_name:  ColumnIndexConvert.convert(:D),  #  4,
      last_name:   ColumnIndexConvert.convert(:E),  #  5,
      birthday:    ColumnIndexConvert.convert(:G),  #  7,
      phone:       ColumnIndexConvert.convert(:N),  # 14,
      alt_phone:   ColumnIndexConvert.convert(:O),  # 15,
      initials:    ColumnIndexConvert.convert(:F),  #  6,
      start_date:  ColumnIndexConvert.convert(:P),  # 16,
      resign_date: ColumnIndexConvert.convert(:Q),  # 17,
      skype:       ColumnIndexConvert.convert(:AE), # 27,
      jabber:      ColumnIndexConvert.convert(:AF), # 28,
      twitter:     ColumnIndexConvert.convert(:AG), # 29,
    }
    # first content rows: (index is 1-based)
    @start_row = 3

    ## initials of resigned employees -- will be ignored and not generated
    @resigned_contacts     = %w()

    @zip_file_name = 'nineconsult-vcards'
    load_config_file
  end

  def load_config_file
    # APP_config contains username/password to Google account
    @conf = YAML.load_file('config.yml')
    Logger.info "loaded config (#{conf.size} lines)"
    Logger.debug conf.inspect
  end
end

# Worksheeter class reads configuration, and employees.
# Then it generates a vcard for each employee
class Worksheeter
  WS_FILE = '.cache/_worksheet.yml'

  def initialize(config)
    @config = config
    FileUtils.mkdir_p 'vcards'
    FileUtils.mkdir_p '.cache'
  end

  def load_worksheet_from_cache
    Logger.info 'Load the worksheet from disk'
    @worksheet = YAML.load_file(WS_FILE)
    rows = @worksheet.rows
    Logger.info "Worksheet title: #{@worksheet.title}"
    Logger.debug "Worksheet contents (#{rows.size} rows)\n=================="
  end

  def load_worksheet
    return load_worksheet_from_cache if @config.local

    conf = @config.conf
    # TODO: return worksheet_from_cache(filename) if false
    # Logs in.
    Logger.info "logs in for #{conf['account']}"
    session = GoogleSpreadsheet.login(conf['account'], conf['account_password'])

    Logger.info 'retrieve the worksheet'
    @worksheet = session.spreadsheet_by_key(conf['spreadsheet_key']).worksheets[0]
    # trigger fetch of data or it will not be written
    rows = @worksheet.rows
    Logger.info 'done'

    Logger.info "Worksheet title: #{@worksheet.title}"
    Logger.debug "Worksheet contents (#{rows.size} rows)\n=================="
    Logger.debug @worksheet.inspect
    File.open(WS_FILE, 'w') { |f| f.write @worksheet.to_yaml }
    Logger.info "Worksheet written to file: #{WS_FILE}"
  end

  def filename(contact_name)
    I18n.enforce_available_locales = false
    I18n.locale = :da
    I18n.transliterate contact_name
  end

  def generate_vcards
    # debugstuff()
    employee_rows.each do |row|
      contact = Contact.new(@config, @worksheet, row)
      # p contact.name

      # only create vcards for the "valid" rows in spreadsheet:
      # valid contacts must have name and email present
      Logger.info "Skipping invalid: #{contact.pretty_print}" unless contact.valid?
      Logger.info "Skipping resigned: #{contact.pretty_print}" if contact.resigned?

      next unless contact.valid? && !contact.resigned?

      filename = "vcards/#{filename(contact.name)}.vcf"
      File.open(filename, 'w',  external_encoding: Encoding::ISO_8859_1) do |f|
        f.write(VCard.new(contact).to_vcard)
        Logger.info "wrote vcard for #{contact.pretty_print(:short)}"
      end
    end
  end

  # fetching the Gravatar fotos for each mail address in `gravatar_email_suffix`
  def fetch_photos
    employee_rows.each do |row|
      contact = Contact.new(@config, @worksheet, row)
      if contact.valid?
        Logger.info "fetching #{contact.initials}: #{contact.photo_url}"
        `curl -s #{contact.photo_url} > .cache/#{contact.initials}.jpg `
      end
    end
  end

  def build_instructions
    filename    = 'INSTRUCTIONS.erb.md'
    erb_binding = binding
    @spreadsheet_key = @config.conf['spreadsheet_key']
    template = ERB.new(File.read(filename), nil, '<>')
    contents = template.result(erb_binding)

    File.open("vcards/#{filename.gsub('erb.', '')}", 'w') do |f|
      f.write(contents)
    end
  end

  def zip_folder
    `zip -9 #{ @config.zip_file_name }-#{ Date.today.to_s  }.zip vcards/* `
  end

  def employee_rows
    @config.start_row..@worksheet.num_rows
  end
end

# slurp command line options and build the vcards
class VcardBuilder
  def parse_options
    optparse = OptionParser.new do|opts|
      # Set a banner, displayed at the top of the help screen.
      opts.banner = 'Usage: .build.rb [options] '
      opts.on('-v', '--verbose', 'Output more information') do
        Logger.allow_info = true
      end
      opts.on('--debug', 'Output even more information') do
        Logger.allow_info = true
        Logger.allow_debug = true
      end
      opts.on('--local', 'Use local cached photos and worksheet') do
        @conf.local = true
      end

      opts.on('-h', '--help', 'Prints this help') do
        puts opts
        exit
      end
    end
    # parse the command line arguments
    optparse.parse!
  end

  def initialize
    @conf = Conf.new
    # options will be added to @conf
    parse_options

    Logger.info 'Verbose setting selected. Writing extra info'
    Logger.debug 'Even more verbose setting selected. Writing even more info'
    Logger.info '--local set. Using cache instead of making new requests' if @conf.local

    ws = Worksheeter.new(@conf)
    puts 'Loading worksheet...'
    ws.load_worksheet
    puts 'Fetching photos..'
    ws.fetch_photos unless @conf.local
    puts 'Generating vcards..'
    ws.generate_vcards
    ws.build_instructions
    puts 'Writing zip file..'
    ws.zip_folder
    puts 'Done'
  end
end

VcardBuilder.new
