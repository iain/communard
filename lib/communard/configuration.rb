require "logger"
require "pathname"

module Communard
  class Configuration

    attr_accessor :environment, :root, :logger, :dump_same_db

    def initialize
      self.environment  = ENV["RACK_ENV"] || ENV["RUBY_ENV"] || ENV["RACK_ENV"] || "development"
      self.root         = Pathname(Dir.pwd)
      self.logger       = default_logger
      self.dump_same_db = false
      yield self if block_given?
    end

    def dump_same_db!
      self.dump_same_db = true
    end

    private

    def default_logger
      ::Logger.new($stdout).tap { |l|
        alternate = 0
        l.formatter = proc { |sev, _, _, msg|
          color = sev == "INFO" ? 35 + ((alternate += 1) % 2) : 31
          "\e[#{color}m[#{sev}]\e[0m #{msg}\n"
        }
      }
    end

  end
end
