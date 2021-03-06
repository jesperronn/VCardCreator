# encoding: UTF-8
# frozen_string_literal: true
require 'rubygems'
# require 'google_spreadsheet'
require 'google_drive'

# Worksheeter class reads configuration, and employees.
# Then it generates a vcard for each employee
class Worksheeter
  def initialize(config)
    @config = config
    FileUtils.mkdir_p config.output_folder
    FileUtils.mkdir_p config.photo_cache
  end

  def load_worksheet_from_cache
    file = @config.cache_file_name
    Loggr.info 'Load the worksheet from disk'
    raise "Missing file '#{file}' in #{`pwd`}" unless File.exist?(file)
    contents = File.read(file)
    Loggr.debug '====file contents: ===='
    Loggr.debug contents
    Loggr.debug '====end file ===='
    YAML.load(contents)
  end

  def load_worksheet_from_net(key)
    #    session = GoogleSpreadsheet.login(account, pw)
    # Creates a session. This will prompt the credential via command line for the
    # first time and save it to config.json file for later usages.
    session = GoogleDrive::Session.from_config('config.json')

    Loggr.info "retrieve the worksheet key #{key}"
    worksheet = session.spreadsheet_by_key(key).worksheets[0]

    Loggr.info "Worksheet title: #{worksheet.title}"
    puts 'Fetching rows..'
    worksheet.rows
  end

  def write_worksheet_rows_to_file(rows)
    filename = @config['cache_file_name']
    File.open(filename, 'w') { |f| f.write rows.to_yaml }
    Loggr.info "#{rows.size} Worksheet rows written to file: #{filename}"
  end

  def load_worksheet
    if @config.local
      @rows = load_worksheet_from_cache
    else
      @rows = load_worksheet_from_net(
        @config['spreadsheet_key']
      )
      write_worksheet_rows_to_file(@rows)
    end

    Loggr.info 'done'
    Loggr.debug "Worksheet contents (#{@rows.size} rows)\n=================="
  end

  def generate_contacts
    contacts = employee_rows.map do |num|
      contact = Contact.new(@config, @rows[num], num)
      # only create vcards for the "valid" rows in spreadsheet:
      # valid contacts must have name and email present
      Loggr.info "Skipping invalid: #{contact.pretty}" unless contact.valid?
      Loggr.info "Skipping resigned: #{contact.pretty}" if contact.resigned?

      next unless contact.valid? && !contact.resigned?
      contact
    end.compact
    contacts
  end

  def generate_vcards(contacts)
    contacts.each { |c| c.write_to_file(@config) }
  end

  # fetching the Gravatar fotos for each mail address in `gravatar_email_suffix`
  def fetch_photos(contacts)
    return if @config.local
    contacts.each do |contact|
      next unless contact.valid?
      filename = "#{@config.photo_cache}/#{contact.initials}.jpg"
      if contact.photo_url =~ /https?:/
        Loggr.info "fetching #{contact.initials}: #{contact.photo_url}"
        `curl -s #{contact.photo_url} > #{filename}`
      else
        Loggr.warn "Warning: No photo_url for #{contact.pretty(:short)}"
      end
    end
  end

  def build_instructions
    filename    = 'INSTRUCTIONS.erb.md'
    erb_binding = binding
    @spreadsheet_key = @config['spreadsheet_key']
    template = ERB.new(File.read(filename), nil, '<>')
    contents = template.result(erb_binding)

    File.open("#{@config.output_folder}/#{filename.gsub('erb.', '')}", 'w') do |f|
      f.write(contents)
    end
  end

  def zip_folder
    src = "#{@config.output_folder}/*"
    `zip -9 #{ @config.zip_file_name }-#{ Date.today.to_s }.zip #{ src }`
  end

  def employee_rows
    @config.start_row..@rows.size
  end
end
