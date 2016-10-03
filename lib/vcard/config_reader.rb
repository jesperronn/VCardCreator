# frozen_string_literal: true
# configuration file reader.
# can read and convert into the required format by
# Config class
class ConfigReader
  def read_config(cmd_options)
    filename = cmd_options[:filename]
    config_file = load_config_file(filename)
    # columns for this spreadsheet (0-index) OR you can use letters :A-:Z
    # we keep the array for keeping sort order
    columns = []
    config_file['columns'].each do |item|
      item.each_pair do |k, v|
        columns.push Hash[k, ColumnIndexConvert.convert(v)]
      end
    end
    config_file['columns'] = columns
    # create Struct from hash values:
    c = Config.new(*symbolize_keys(config_file).values_at(*Config.members))
    cmd_options.each_pair do |k, v|
      c[k] = v
    end
    c
  end

  def symbolize_keys(hash)
    Hash[hash.map { |k, v| [k.to_sym, v] }]
  end

  def load_config_file(filename)
    Loggr.info 'Loading config from file'
    raise "no file found at '#{filename}'" unless File.exist? filename
    # APP_config contains username/password to Google account
    config_file = YAML.load_file(filename)

    puts "loaded config (#{config_file.size} lines)"
    Loggr.info "loaded config (#{config_file.size} lines)"
    config_file
  end
end
