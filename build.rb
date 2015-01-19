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

# log via this class
# USAGE
#
# Logger.allow_debug = true # set this once
#
# Logger.info "text to log"
#
class Logger
  class << self
    attr_accessor :allow_debug, :allow_info
    def info(s)
      puts "[INFO]  " << s if allow_info
    end

    def debug(s)
      puts "[DEBUG] " << s if allow_debug
    end
  end
end


# Configuration class takes care of all config
class Conf
  Logger.info "Loading config from file"
  attr_accessor :columns, :start_row, :worksheet, :resigned_contacts,
                :spreadsheet_key, :zip_file_name

  def initialize
    # columns for this spreadsheet (1-index)
    @columns  = {
      first_name: 3,
      last_name:  4,
      birthday:   5,
      phone:     15,
      alt_phone: 16,
      email:     18,
      skype:     12,
      jabber:    13,
      twitter:   14
      # TODO: add employment date
    }

    # APP_config contains username/password to Google account
    conf = YAML.load_file('config.yml')
    Logger.info "loaded config (#{conf.size} lines)"
    Logger.debug conf.inspect

    # Logs in.
    # You can also use OAuth. See document of GoogleSpreadsheet.login_with_oauth for details.
    Logger.info "logs in for #{conf['account']}"
    session = GoogleSpreadsheet.login(conf['account'], conf['account_password'])

    Logger.info "retrieve the worksheet"
    @spreadsheet_key = conf['spreadsheet_key']
    @worksheet = session.spreadsheet_by_key(@spreadsheet_key).worksheets[0]
    Logger.info "done"

    Logger.info "Worksheet title: #{@worksheet.title}"
    Logger.debug "Worksheet contents\n=================="
    Logger.debug @worksheet.inspect

    # first content rows: (index is 1-based)
    @start_row = 3

    ## initials of resigned employees -- will be ignored and not generated
    @resigned_contacts     = %w(thm mbw el pfa)

    @zip_file_name = 'nineconsult-vcards'
  end
end

# Generates a Contact class for each employee
class Contact
  @@org                   = 'NineConsult A/S'
  @@email_suffix          = '@nineconsult.dk'
  @@gravatar_email_suffix = '@nineconsult.dk'

  attr_accessor :name, :first_name, :last_name, :initials, :phone, :alt_phone,
                :skype, :jabber, :twitter, :birthday, :org, :resigned
  # initialize a contact with with values from the worksheet row
  alias :resigned? :resigned

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
    @org        = @@org

    @resigned = config.resigned_contacts.include? @initials
  end

  # valid contacts must have name and email present
  def valid?
    !(@initials.empty? || @first_name.empty? || @last_name.empty?)
  end

  # returns a gravatar url based on the email address
  def photo_url
    mail_nine_dk = @email.strip.downcase + @@gravatar_email_suffix
    mail_hash = Digest::MD5.hexdigest(mail_nine_dk)
    "http://www.gravatar.com/avatar/#{mail_hash}?s=150"
  end

  # returns full email address
  def email
    @email + @@email_suffix
  end

  def pretty_print
    out = '#<' << self.class.to_s
    %i(first_name last_name initials email).each do |prop|
      out << ' @' << "#{prop.to_s}='#{self.send prop}'"
    end
    out << ">"
  end
end

# VCard class must contain the actual generation of the card.
# it should read values from a Contact object
class VCard
  @@country_code = '+45'

  def initialize(contact)
    @contact = contact
  end

  def twitter
    # remember to remove any @-signs from the twitter name in url
    twit_url = "http://twitter.com/#!/#{@contact.twitter.gsub(/^\@/, '')}"
    return '' if @contact.twitter.empty?

    "X-SOCIALPROFILE;type=twitter:#{twit_url}\n"
  end

  def skype
    return '' if @contact.skype.empty?

    # "X-SERVICE-SKYPE:Skype:#{@contact.skype}\n"
    "item1.IMPP;X-SERVICE-TYPE=Skype:skype:#{@contact.skype}\n"
  end

  def phone
    return 'TEL;type=CELL;type=VOICE:' if @contact.phone.empty?

    "TEL;type=CELL;type=VOICE;type=pref:#{@@country_code} #{@contact.phone}"
  end

  def alt_phone
    return '' if @contact.alt_phone.empty?

    "TEL;type=HOME;type=VOICE:#{@@country_code} #{@contact.alt_phone}\n"
  end

  def birthday
    return '' if @contact.birthday.empty?

    "BDAY:#{ Date.parse(@contact.birthday) }"
  end

  def photo
    filename = ".photo_cache/#{@contact.initials}.jpg"
    # puts "#{@contact.initials} exists? #{File.exists?(filename)}"
    if File.exist?(filename)
      file_contents = File.read(filename)
      Base64.strict_encode64(file_contents)
      # file_contents.split('\n').each{|line| line.prepend(' ')}
    end
  end

  def to_vcard
    # debugger
    first_part    = <<-ENDVCARD.gsub(/^\s+/, '')
                    BEGIN:VCARD
                    VERSION:3.0
                    N;CHARSET=iso-8859-1:#{@contact.last_name};#{@contact.first_name};;;
                    FN;CHARSET=iso-8859-1: #{@contact.name}
                    ORG:#{@contact.org}
                    #{phone}
                    EMAIL:#{@contact.email}
                    #{birthday}
                    PHOTO;ENCODING=b;TYPE=JPEG:#{photo}
                    ENDVCARD

    last_part    = <<-ENDVCARD.gsub(/^\s+/, '')
                    END:VCARD
                    ENDVCARD
    first_part + alt_phone + twitter + skype + last_part
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
      Logger.info "Skipping invalid contact: #{contact.pretty_print}" unless contact.valid?
      Logger.info "Skipping resigned contact: #{contact.pretty_print}" if  contact.resigned?

      next unless contact.valid? && !contact.resigned?

      filename = "vcards/#{filename(contact.name)}.vcf"
      File.open(filename, 'w',  external_encoding: Encoding::ISO_8859_1) do |f|
        f.write(VCard.new(contact).to_vcard)
      end
    end
  end

  # fetching the Gravatar fotos for each email address in <tt>gravatar_email_suffix</tt>
  def fetch_photos
    employee_rows.each do |row|
      contact = Contact.new(@config, @ws, row)
      if contact.valid?
        puts "fetching #{contact.initials}: #{contact.photo_url}"
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
  def initialize
    options = {}
    optparse = OptionParser.new do|opts|
      # Set a banner, displayed at the top of the help screen.
      opts.banner = "Usage: .build.rb [options] "
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

    Logger.info "Verbose setting selected. Writing extra info"
    Logger.debug "Even more verbose setting selected. Writing even more info"

    conf = Conf.new
    ws = Worksheeter.new(conf)
    ws.fetch_photos
    ws.generate_vcards
    ws.build_instructions
    ws.zip_folder
  end
end

VcardBuilder.new
