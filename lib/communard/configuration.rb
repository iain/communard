require "logger"
require "pathname"

module Communard
  class Configuration

    attr_accessor :environment, :root, :logger

    def initialize
      self.environment = ENV["RACK_ENV"] || ENV["RUBY_ENV"] || ENV["RACK_ENV"] || "development"
      self.root        = Pathname(Dir.pwd)
      self.logger      = default_logger
      yield self if block_given?
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
