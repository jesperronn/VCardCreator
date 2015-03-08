# configuration file reader.
# can read and convert into the required format by
# Config class
class ConfigReader
  def read_config(filename)
    conf = load_config_file(filename)
    # columns for this spreadsheet (0-index) OR you can use letters :A-:Z
    # we keep the array for keeping sort order
    columns = []
    conf['columns'].each do |item|
      item.each_pair do |k, v|
        columns.push Hash[k, ColumnIndexConvert.convert(v)]
      end
    end
    conf['columns'] = columns
    # create Struct from hash values:
    Config.new(*symbolize_keys(conf).values_at(*Config.members))
  end

  def symbolize_keys(hash)
    Hash[hash.map { |k, v| [k.to_sym, v] }]
  end

  def load_config_file(filename)
    Logger.info 'Loading config from file'
    # APP_config contains username/password to Google account
    conf = YAML.load_file(filename)
    Logger.info "loaded config (#{conf.size} lines)"
    conf
  end
end
