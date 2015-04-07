# encoding: UTF-8
require 'rubygems'
require 'google_spreadsheet'

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
    fail "Missing file '#{file}' in #{`pwd`}" unless File.exist?(file)
    Loggr.debug '====file contents: ===='
    Loggr.debug File.read(file)
    Loggr.debug '====end file ===='
    YAML.load_file(file)
  end

  def load_worksheet_from_net(account, pw, key)
    Loggr.info "logs in for #{account}"
    session = GoogleSpreadsheet.login(account, pw)

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
        @config['account'],
        @config['password'],
        @config['spreadsheet_key'])
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
      Loggr.info "fetching #{contact.initials}: #{contact.photo_url}"
      `curl -s #{contact.photo_url} > #{filename}`
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
    src =  "#{ @config.output_folder }/*"
    `zip -9 #{ @config.zip_file_name }-#{ Date.today.to_s  }.zip #{ src }`
  end

  def employee_rows
    @config.start_row..@rows.size
  end
end
