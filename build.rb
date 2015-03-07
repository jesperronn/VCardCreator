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
    # columns for this spreadsheet (0-index) OR you can use letters :A-:Z
    @columns  = {
      first_name:  ColumnIndexConvert.convert(:D),
      last_name:   ColumnIndexConvert.convert(:E),
      birthday:    ColumnIndexConvert.convert(:G),
      phone:       ColumnIndexConvert.convert(:N),
      alt_phone:   ColumnIndexConvert.convert(:O),
      initials:    ColumnIndexConvert.convert(:F),
      start_date:  ColumnIndexConvert.convert(:P),
      resign_date: ColumnIndexConvert.convert(:Q),
      linkedin:    ColumnIndexConvert.convert(:AD),
      skype:       ColumnIndexConvert.convert(:AE),
      jabber:      ColumnIndexConvert.convert(:AF),
      twitter:     ColumnIndexConvert.convert(:AG)
    }
    # first content rows: (index is 0-based)
    @start_row = 2

    ## initials of resigned employees -- will be ignored and not generated
    @resigned_contacts     = %w()

    @zip_file_name = 'nineconsult-vcards'
    load_config_file
  end

  def load_config_file
    # APP_config contains username/password to Google account
    @conf = YAML.load_file('config.yml')
    Logger.info "loaded config (#{conf.size} lines)"
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
    YAML.load_file(WS_FILE)
  end

  def load_worksheet_from_net(account, pw, key)
    Logger.info "logs in for #{account}"
    session = GoogleSpreadsheet.login(account, pw)

    Logger.info "retrieve the worksheet key #{key}"
    worksheet = session.spreadsheet_by_key(key).worksheets[0]

    Logger.info "Worksheet title: #{worksheet.title}"
    puts 'Fetching rows..'
    worksheet.rows
  end

  def write_worksheet_rows_to_file(rows)
    File.open(WS_FILE, 'w') { |f| f.write rows.to_yaml }
    Logger.info "#{rows.size} Worksheet rows written to file: #{WS_FILE}"
  end

  def load_worksheet
    if @config.local
      @rows = load_worksheet_from_cache
    else
      @rows = load_worksheet_from_net(
        @config.conf['account'],
        @config.conf['account_password'],
        @config.conf['spreadsheet_key'])
      write_worksheet_rows_to_file(@rows)
    end

    Logger.info 'done'
    Logger.debug "Worksheet contents (#{@rows.size} rows)\n=================="
  end

  def generate_contacts
    contacts = employee_rows.map do |num|
      contact = Contact.new(@config, @rows[num], num)
      # only create vcards for the "valid" rows in spreadsheet:
      # valid contacts must have name and email present
      Logger.info "Skipping invalid: #{contact.pretty}" unless contact.valid?
      Logger.info "Skipping resigned: #{contact.pretty}" if contact.resigned?

      next unless contact.valid? && !contact.resigned?
      contact
    end.compact
    contacts
  end

  def generate_vcards(contacts)
    contacts.each(&:write_to_file)
  end

  # fetching the Gravatar fotos for each mail address in `gravatar_email_suffix`
  def fetch_photos(contacts)
    return if @config.local
    contacts.each do |contact|
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
    @config.start_row..@rows.size
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
    Logger.info '--local set. Using cache instead of http requests' if @conf.local

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

VcardBuilder.new
