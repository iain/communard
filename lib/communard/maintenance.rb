module Communard
  class Maintenance

    attr_reader :connection, :root

    def initialize(connection: nil, root: nil)
      ::Sequel.extension :migration, :core_extensions
      @connection = connection
      @root       = root
    end

    def migrate(target: nil)
      target = Integer(target) if target
      ::Sequel::Migrator.run(connection, migrations, target: target, allow_missing_migration_files: true)
      dump_schema
    end

    def seed
      load seeds_file if seeds_file.exist?
    end

    def rollback(step: 1)
      target = applied_migrations[-step - 1]
      if target
        migrate(target: target.split(/_/, 2).first)
      else
        fail ArgumentError, "Cannot roll back that far"
      end
    end

    def load_schema
      migration = instance_eval(schema_file.read, schema_file.expand_path.to_s, 1)
      migration.apply(connection, :up)
    end

    def dump_schema
      connection.extension :schema_dumper
      schema = connection.dump_schema_migration(same_db: false)
      schema_file.open("w") { |f| f << schema.gsub(/\s+$/m, "") }
    end

    def status
      results = Hash.new { |h,k| h[k] = Status.new(k, false, false) }
      available = Pathname.glob(migrations.join("*.rb")).map(&:basename).map(&:to_s).reverse
      available.each { |migration| results[migration].available = true }
      applied_migrations.each { |migration| results[migration].applied = true }

      puts
      puts "database: #{connection.opts.fetch(:database)}"
      puts
      puts " Status   Migration ID    Migration Name"
      puts "--------------------------------------------------"
      results.values.sort.each do |result|
        puts "  #{result.status}    #{result.id}  #{result.name}"
      end
      puts
    end

    private

    def applied_migrations
      ::Sequel::Migrator.migrator_class(migrations).new(connection, migrations, allow_missing_migration_files: true).applied_migrations
    end

    def schema_file
      root.join("db/schema.rb")
    end

    def seeds_file
      root.join("db/seeds.rb")
    end

    def migrations
      root.join("db/migrate")
    end

    Status = Struct.new(:file, :applied, :available) do

      def <=>(other)
        id <=> other.id
      end

      def status
        available ? applied ? " up " : "down" : "????"
      end

      def id
        splitted.first
      end

      def name
        splitted.last.capitalize.gsub("_", " ").sub(/\.rb$/, "")
      end

      def splitted
        file.split(/_/, 2)
      end

    end

  end
end
