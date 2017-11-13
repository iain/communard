require "pathname"
require "logger"
require "uri"

module Communard
  class Configuration

    attr_reader :options

    def initialize(conn_string = ENV["DATABASE_URL"], opts = Sequel::OPTS)
      @conn_string = conn_string
      @opts = opts

      case conn_string
      when String
        uri = URI.parse(conn_string)
        @options = {
          "adapter"  => uri.scheme,
          "user"     => uri.user,
          "password" => uri.password,
          "port"     => uri.port,
          "host"     => uri.hostname,
          "database" => (m = %r{/(.*)}.match(uri.path)) && (m[1]),
        }
      when Hash
        @options = conn_string.map { |k, v| [ k.to_s, v ] }.to_h
      else
        raise ArgumentError, "Sequel::Database.connect takes either a Hash or a String, given: #{conn_string.inspect}"
      end

      self.db_path = Pathname(Dir.pwd).join("db")
      self.logger = nil
      self.dump_after_migrating = false
      self.same_db = true

      yield self if block_given?
    end

    attr_accessor :logger

    attr_accessor :same_db

    attr_accessor :dump_after_migrating

    attr_reader :db_path

    def db_path=(path)
      @db_path = Pathname(path)
    end

    def connection
      Sequel.connect(@conn_string, @opts).tap { |c|
        c.loggers = [logger, default_logger].compact
        c.sql_log_level = :debug
      }
    end

    def silent_connection
      Sequel.connect(@conn_string, @opts).tap { |c|
        c.loggers = [logger].compact
      }
    end

    def default_logger(out = $stdout)
      ::Logger.new(out).tap { |l|
        alternate = 0
        l.formatter = Proc.new { |sev, _, _, msg|
          alternate = ((alternate + 1) % 2)
          msg = if sev == "DEBUG"
                  "       #{msg}"
                else
                  "[#{sev}] #{msg}"
                end
          if out.tty?
            color = case sev
                    when "INFO" then 35 + alternate
                    when "DEBUG" then 30
                    else 31
                    end
            "\e[#{color}m#{msg}\e[0m\n"
          else
            "#{msg}\n"
          end
        }
      }
    end

    def adapter
      options.fetch("adapter")
    end

    def database_name
      options.fetch("database")
    end

  end
end
