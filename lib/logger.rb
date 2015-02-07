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
      puts '[INFO]  ' << s if allow_info
    end

    def debug(s)
      puts '[DEBUG] ' << s if allow_debug
    end
  end
end
