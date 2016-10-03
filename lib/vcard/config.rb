# frozen_string_literal: true
require 'ostruct'
# Configuration class takes care of all config
Config = Struct.new(:columns, :start_row, :worksheet, :resigned_contacts,
                    :local, :cache_file_name, :zip_file_name, :photo_cache,
                    :output_folder, :spreadsheet_key, :filename) do
  # make sure all required params are loaded from config
  REQUIRED = %i(columns start_row cache_file_name zip_file_name photo_cache
                output_folder spreadsheet_key).freeze
  def ensure_required_params
    REQUIRED.each do |k|
      prop = send(k)
      Loggr.debug "validating #{k} (#{prop.class})"

      raise "FATAL: missing param :#{k} in Configuration" if prop.nil?
    end
  end
end
