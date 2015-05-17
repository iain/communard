require "sequel"
require "logger"
require "pathname"

require "communard/version"
require "communard/maintenance"
require "communard/configuration"
require "communard/context"

module Communard

  def self.connect(&block)
    context(&block).connect
  end

  def self.context(&block)
    Context.new(configuration(&block))
  end

  def self.configuration(&block)
    Configuration.new(&block)
  end

end
