# Configuration class takes care of all config
Config = Struct.new(:columns, :start_row, :worksheet, :resigned_contacts, :local,
                    :cache_file_name, :zip_file_name, :photo_cache, :output_folder,
                    :spreadsheet_key, :account, :password) do
  # make sure all required params are loaded from config
  REQUIRED = %i(columns start_row cache_file_name zip_file_name photo_cache output_folder
                spreadsheet_key account password)
  def ensure_required_params
    REQUIRED.each do |k|
      fail "FATAL: missing param :#{k} in Configuration" if send(k).nil?
    end
  end
end
