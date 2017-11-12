require "sequel/core"

require "communard/version"
require "communard/configuration"
require "communard/commands"

module Communard

  def self.commands(*args, &block)
    Commands.new(configuration(*args, &block))
  end

  def self.configuration(*args, &block)
    Configuration.new(*args, &block)
  end

end
