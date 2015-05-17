module Communard
  class Context

    attr_reader :configuration

    def initialize(configuration)
      @configuration = configuration
    end

    def connect(opts = options)
      ::Sequel.connect(opts).tap do |connection|
        connection.loggers = loggers
        connection.sql_log_level = configuration.sql_log_level
        connection.log_warn_duration = configuration.log_warn_duration
      end
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
      unless adapter(env: env) == "sqlite"
        run_without_database("CREATE DATABASE %{database_name}", env: env)
      end
    rescue Sequel::DatabaseError => error
      if /database (.*) already exists/ === error.message
        loggers.each { |logger| logger.info "Database #{$1} already exists, which is fine." }
      else
        raise
      end
    end

    def drop_database(env: environment)
      fail ArgumentError, "Don't drop the production database, you monkey!" if env.to_s == "production"
      if adapter(env: env) == "sqlite"
        file = options(env: env).fetch("database")
        if File.exist?(file)
          File.rm(file)
        end
      else
        run_without_database("DROP DATABASE IF EXISTS %{database_name}", env: env)
      end
    end

    def migrate(target: nil, env: environment)
      maintenance(env: env).migrate(target: target, dump_same_db: configuration.dump_same_db)
    end

    def seed(env: environment)
      maintenance(env: env).seed
    end

    def rollback(step: 1, env: environment)
      maintenance(env: env).rollback(step: step, dump_same_db: configuration.dump_same_db)
    end

    def load_schema(env: environment)
      maintenance(env: env).load_schema
    end

    def dump_schema(env: environment)
      maintenance(env: env).dump_schema(dump_same_db: configuration.dump_same_db)
    end

    def status(env: environment)
      maintenance(env: env).status
    end

    def run_without_database(cmd, env: environment)
      opts = options(env: env).dup
      database_name = opts.delete("database")
      if opts.fetch("adapter") == "postgres"
        opts["database"]           = "postgres"
        opts["schema_search_path"] = "public"
      end
      connection = connect(opts)
      connection.run(cmd % { database_name: database_name })
    end

    def options(env: environment)
      YAML.load_file(root.join("config/database.yml")).fetch(env.to_s)
    end

    private

    def maintenance(env: environment)
      Maintenance.new(connection: connect(options(env: env)), root: root)
    end

    def environment
      configuration.environment
    end

    def root
      configuration.root
    end

    def loggers
      configuration.loggers
    end

    def adapter(env: environment)
      options(env: env).fetch("adapter").to_s
    end

  end
end
