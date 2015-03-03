#!/usr/bin/env ruby
# encoding: UTF-8
require 'rubygems'
require 'google_spreadsheet'
require 'fileutils'
require 'digest/md5'
require 'erb'
require 'yaml'
require 'pp'
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
                :spreadsheet_key, :zip_file_name

  def initialize
    # columns for this spreadsheet (1-index) OR you can use letters :A-:Z
    @columns  = {
      first_name:  ColumnIndexConvert.convert(:D), #  4,
      last_name:   ColumnIndexConvert.convert(:E), #  5,
      birthday:    ColumnIndexConvert.convert(:G), #  7,
      phone:       ColumnIndexConvert.convert(:N), # 14,
      alt_phone:   ColumnIndexConvert.convert(:O), # 15,
      email:       ColumnIndexConvert.convert(:F), #  6,
      start_date:  ColumnIndexConvert.convert(:P), # 16,
      resign_date: ColumnIndexConvert.convert(:Q), # 17,
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
    conf = YAML.load_file('config.yml')
    Logger.info "loaded config (#{conf.size} lines)"
    Logger.debug conf.inspect

    # Logs in.
    Logger.info "logs in for #{conf['account']}"
    session = GoogleSpreadsheet.login(conf['account'], conf['account_password'])

    Logger.info 'retrieve the worksheet'
    @spreadsheet_key = conf['spreadsheet_key']
    @worksheet = session.spreadsheet_by_key(@spreadsheet_key).worksheets[0]
    Logger.info 'done'

    Logger.info "Worksheet title: #{@worksheet.title}"
    Logger.debug "Worksheet contents\n=================="
    Logger.debug @worksheet.inspect
  end
end

# Generates a Contact class for each employee
class Contact
  ORG                   = 'NineConsult A/S'
  EMAIL_SUFFIX          = '@nine.dk'
  GRAVATAR_EMAIL_SUFFIX = '@nineconsult.dk'

  attr_accessor :name, :first_name, :last_name, :initials, :phone, :alt_phone,
                :skype, :jabber, :twitter, :birthday, :org, :resigned, :row_num
  # initialize a contact with with values from the worksheet row
  alias_method :resigned?, :resigned

  def initialize(config, ws, row)
    idx = config.columns
    #    p ws
    #    p row
    #    p idx[:first_name]
    @first_name = ws[row, idx[:first_name]]
    @last_name  = ws[row, idx[:last_name]]
    @name       = "#{@first_name} #{@last_name}"
    @initials   = ws[row, idx[:email]]
    @phone      = ws[row, idx[:phone]]
    @alt_phone  = ws[row, idx[:alt_phone]]
    @email      = ws[row, idx[:email]]
    @skype      = ws[row, idx[:skype]]
    @jabber     = ws[row, idx[:jabber]]
    @twitter    = ws[row, idx[:twitter]]
    @birthday   = ws[row, idx[:birthday]]
    @org        = ORG
    @row_num    = row

    @resigned = config.resigned_contacts.include? @initials
  end

  # valid contacts must have name and email present
  def valid?
    !(@initials.empty? || @first_name.empty? || @last_name.empty?)
  end

  # returns a gravatar url based on the email address
  def photo_url
    mail_nine_dk = @email.strip.downcase + GRAVATAR_EMAIL_SUFFIX
    mail_hash = Digest::MD5.hexdigest(mail_nine_dk)
    "http://www.gravatar.com/avatar/#{mail_hash}?s=150"
  end

  # returns full email address
  def email
    @email + EMAIL_SUFFIX
  end

  def pretty_print(format = :long)
    out = '#<' << self.class.to_s
    props = case format
            when :short
              %i(initials name)
            when :long
              %i(first_name last_name initials email row_num)
            else
              fail RuntimeError "format #{format} not recognized"
            end
    props.each do |prop|
      out << ' @' << "#{prop}='#{send prop}'"
    end
    out << '>'
  end
end

# Worksheeter class reads configuration, and employees.
# Then it generates a vcard for each employee
class Worksheeter
  def initialize(config)
    @ws = config.worksheet
    @config = config

    FileUtils.mkdir_p 'vcards'
    FileUtils.mkdir_p '.photo_cache'
  end

  def filename(contact_name)
    I18n.enforce_available_locales = false
    I18n.locale = :da
    I18n.transliterate contact_name
  end

  def generate_vcards
    # debugstuff()
    employee_rows.each do |row|
      contact = Contact.new(@config, @ws, row)
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
      contact = Contact.new(@config, @ws, row)
      if contact.valid?
        Logger.info "fetching #{contact.initials}: #{contact.photo_url}"
        `curl -s #{contact.photo_url} > .photo_cache/#{contact.initials}.jpg `
      end
    end
  end

  def build_instructions
    filename    = 'INSTRUCTIONS.erb.md'
    erb_binding = binding
    @spreadsheet_key = @config.spreadsheet_key
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
    @config.start_row..@ws.num_rows
  end
end

# slurp command line options and build the vcards
class VcardBuilder
  def parse_options
    @options ||= begin
      options = {}
      optparse = OptionParser.new do|opts|
        # Set a banner, displayed at the top of the help screen.
        opts.banner = 'Usage: .build.rb [options] '
        options[:verbose] = false
        opts.on('-v', '--verbose', 'Output more information') do
          options[:verbose] = true
        end
        opts.on('--debug', 'Output even more information') do
          options[:verbose] = true
          options[:debug] = true
        end
      end
      # parse the command line arguments
      optparse.parse!

      Logger.allow_info = options[:verbose]
      Logger.allow_debug = options[:debug]
    end
  end

  def initialize
    parse_options
    Logger.info 'Verbose setting selected. Writing extra info'
    Logger.debug 'Even more verbose setting selected. Writing even more info'

    conf = Conf.new
    ws = Worksheeter.new(conf)
    puts 'Fetching photos..'
    ws.fetch_photos
    puts 'Generating vcards..'
    ws.generate_vcards
    ws.build_instructions
    puts 'Writing zip file..'
    ws.zip_folder
    puts 'Done'
  end
end

VcardBuilder.new
