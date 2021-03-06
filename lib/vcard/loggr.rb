# frozen_string_literal: true
# log via this class
# USAGE
#
# Loggr.allow_debug = true # set this once
#
# Loggr.info "text to log"
#
class Loggr
  class << self
    attr_accessor :allow_debug, :allow_info
    def warn(s)
      puts '[WARN]  ' << s
    end

    def info(s)
      puts %([INFO]  #{s}) if allow_info
    end

    def debug(s)
      puts %([DEBUG] #{s}) if allow_debug
    end
  end
end
