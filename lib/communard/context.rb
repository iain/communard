require "sequel"

module Communard
  class Context

    attr_reader :configuration

    def initialize(configuration)
      @configuration = configuration
    end

    def connect(opts = options)
      connection = ::Sequel.connect(opts)
      connection.loggers = [logger]
      connection
    end

    def generate_migration(name: nil)
      fail ArgumentError, "Name is required" if name.to_s == ""
      require "fileutils"
      underscore = name.
        gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        tr("-", "_").
        downcase
      filename = root.join("db/migrate/#{Time.now.strftime("%Y%m%d%H%M%S")}_#{underscore}.rb")
      FileUtils.mkdir_p(File.dirname(filename))
      File.open(filename, "w") { |f| f << "Sequel.migration do\n  change do\n  end\nend" }
      puts "#{filename} created"
    end

    def create_database(env: environment)
      run_without_database("CREATE DATABASE IF NOT EXISTS %{database_name}", env: env)
    end

    def drop_database(env: environment)
      fail ArgumentError, "Don't drop the production database, you monkey!" if env.to_s == "production"
      run_without_database("DROP DATABASE IF EXISTS %{database_name}", env: env)
    end

    def migrate(target: nil, env: environment)
      maintenance(env: env).migrate(target: target)
    end

    def seed(env: environment)
      maintenance(env: env).seed
    end

    def rollback(step: 1, env: environment)
      maintenance(env: env).rollback(step: step)
    end

    def load_schema(env: environment)
      maintenance(env: env).load_schema
    end

    def dump_schema(env: environment)
      maintenance(env: env).dump_schema
    end

    def status(env: environment)
      maintenance(env: env).status
    end

    def run_without_database(cmd, env: environment)
      opts = options(env: env).dup
      database_name = opts.delete("database")
      connection = connect(opts)
      connection.run(cmd % { database_name: database_name })
    end

    def options(env: environment)
      YAML.load_file(root.join("config/database.yml")).fetch(env.to_s)
    end

    private

    def maintenance(env: env)
      Maintenance.new(connection: connect(options(env: env)), root: root)
    end

    def environment
      configuration.environment
    end

    def root
      configuration.root
    end

    def logger
      configuration.logger
    end

  end
end
