require "forwardable"

module Communard
  class Commands

    extend Forwardable

    attr_reader :configuration

    def_delegators :configuration,
                   :connection,
                   :adapter,
                   :database_name,
                   :options,
                   :root_path

    def initialize(configuration)
      @configuration = configuration
      Sequel.extension :migration, :core_extensions
    end

    def create_database
      return if adapter == "sqlite"
      run_without_database("CREATE DATABASE %{database_name}")
    rescue Sequel::DatabaseError => error
      if error.message.to_s =~ /database (.*) already exists/
        configuration.default_logger.warn "Database #{$1} already exists."
      else
        raise
      end
    end

    def drop_database
      if adapter == "sqlite"
        file = database_name
        File.rm(file) if File.exist?(file)
      else
        run_without_database("DROP DATABASE IF EXISTS %{database_name}")
      end
    end

    def migrate(target: nil)
      target = Integer(target) if target
      migrator(target: target, current: nil).run
      dump_schema if target.nil? && configuration.dump_after_migrating
    end

    def seed
      load seeds_file if seeds_file.exist?
    end

    def rollback(step: 1)
      available = applied_migrations
      if available.size == 1
        migrate(target: 0)
      else
        target = available[-step - 1]
        if target
          migrate(target: target.split(/_/, 2).first)
        else
          fail ArgumentError, "Cannot roll back to #{step}"
        end
      end
    end

    def load_schema
      migration = instance_eval(schema_file.read, schema_file.expand_path.to_s, 1)
      conn = configuration.silent_connection
      migration.apply(conn, :up)
    end

    def dump_schema
      conn = configuration.silent_connection
      conn.extension :schema_dumper
      schema = conn.dump_schema_migration(same_db: configuration.same_db)
      schema_file.open("w") { |f| f.puts schema.gsub(/^\s+$/m, "").gsub(/:(\w+)=>/, '\1: ') }
    end

    def status
      results = Hash.new { |h, k| h[k] = Status.new(k, false, false) }
      available = Pathname.glob(migrations_dir.join("*.rb")).map(&:basename).map(&:to_s)
      available.each { |migration| results[migration].available = true }
      applied_migrations.each { |migration| results[migration].applied = true }

      $stdout.puts
      $stdout.puts "database: #{connection.opts.fetch(:database)}"
      $stdout.puts
      $stdout.puts " Status   Migration ID    Migration Name"
      $stdout.puts "--------------------------------------------------"
      results.values.sort.each do |result|
        $stdout.puts "  %-7s %-15s %s" % [ result.status, result.id, result.name ]
      end
      $stdout.puts
    end

    def run_without_database(query)
      opts = options.dup
      database_name = opts.delete("database")
      if adapter == "postgres"
        opts["database"]           = "postgres"
        opts["schema_search_path"] = "public"
      end
      conn = Sequel.connect(opts)
      conn.run(query % { database_name: database_name })
    end

    private

    def applied_migrations
      available = Pathname.glob(migrations_dir.join("*.rb")).map(&:basename).map(&:to_s)
      m = migrator(allow_missing_migration_files: true)
      if m.is_a?(Sequel::IntegerMigrator)
        available.select { |f| f.split("_", 2).first.to_i <= m.current }
      else
        m.applied_migrations
      end
    end

    def migrator(opts = {})
      migrator = Sequel::Migrator.migrator_class(migrations_dir)
      migrator.new(connection, migrations_dir, opts)
    end

    def schema_file
      root_path.join("db/schema.rb")
    end

    def seeds_file
      root_path.join("db/seeds.rb")
    end

    def migrations_dir
      root_path.join("db/migrate")
    end

    Status = Struct.new(:file, :applied, :available) do

      def <=>(other)
        id <=> other.id
      end

      def status
        return "????" unless available
        applied ? " up " : "down"
      end

      def id
        splitted.first
      end

      def name
        splitted.last.capitalize.tr("_", " ").sub(/\.rb$/, "")
      end

      def splitted
        file.split(/_/, 2)
      end

    end

  end
end
