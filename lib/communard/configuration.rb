module Communard
  class Configuration

    attr_accessor :environment, :root, :dump_same_db, :loggers, :sql_log_level, :log_warn_duration

    def initialize
      self.environment       = ENV["RACK_ENV"] || ENV["RUBY_ENV"] || ENV["RACK_ENV"] || "development"
      self.root              = Pathname(Dir.pwd)
      self.logger            = stdout_logger
      self.log_level         = :info
      self.dump_same_db      = false
      self.sql_log_level     = :debug
      self.log_warn_duration = 0.5
      yield self if block_given?
    end

    def dump_same_db!
      self.dump_same_db = true
    end

    def logger=(logger)
      self.loggers = [logger]
    end

    def loggers
      Array(@loggers).compact
    end

    def log_level=(level)
      real_level = ::Logger.const_get(level.to_s.upcase)
      loggers.each do |logger|
        logger.level = real_level
      end
    end

    def stdout_logger(out = $stdout)
      ::Logger.new(out).tap { |l|
        alternate = 0
        l.formatter = Proc.new { |sev, _, _, msg|
          alternate = ((alternate + 1) % 2)
          color = case sev
          when "INFO" then 35 + alternate
          when "DEBUG" then 90
          else 31
          end
          "\e[#{color}m[#{sev}]\e[0m #{msg}\n"
        }
      }
    end

  end
end
