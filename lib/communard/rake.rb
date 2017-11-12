require "communard"

module Communard
  class Rake

    extend ::Rake::DSL if defined?(::Rake::DSL)

    def self.add_tasks(*args, &block)
      task :_load_communard do
        @_communard_commands = Communard.commands(*args, &block)
      end

      desc "Creates the database, migrate the schema, and loads seed data"
      task setup: ["db:create", "db:migrate", "db:seed", "db:test:prepare"]

      desc "Creates the database"
      task create: :_load_communard do
        @_communard_commands.create_database
      end

      desc "Drops the database"
      task drop: :_load_communard do
        @_communard_commands.drop_database
      end

      desc "Drops and creates the database"
      task reset: ["db:drop", "db:setup"]

      desc "Migrate the database"
      task migrate: :_load_communard do
        target = ENV["TARGET"]
        @_communard_commands.migrate(target: target)
      end

      desc "Load the seed data from db/seeds.rb"
      task seed: :_load_communard do
        @_communard_commands.seed
      end

      desc "Rolls the schema back to the previous version"
      task rollback: :_load_communard do
        step = Integer(ENV["STEP"] || 1)
        @_communard_commands.rollback(step: step)
      end

      namespace :test do
        desc "Cleans the test database"
        task prepare: :_load_communard do
          env = {
            "RACK_ENV"     => "test",
            "RAILS_ENV"    => "test",
            "RUBY_ENV"     => "test",
            "DATABASE_URL" => nil,
          }
          Process.spawn(env, $PROGRAM_NAME, "db:drop", "db:create", "db:schema:load")
          _pid, status = Process.wait2
          fail "Failed to re-create test database" if status.exitstatus != 0
        end
      end

      namespace :migrate do

        desc "Redo the last migration"
        task redo: :_load_communard do
          commands = @_communard_commands
          commands.rollback
          commands.migrate
        end

        desc "Display status of migrations"
        task status: :_load_communard do
          @_communard_commands.status
        end

        desc "Drop and recreate database with migrations"
        task reset: ["db:drop", "db:create", "db:migrate"]
      end

      namespace :schema do

        desc "Load the schema from db/schema.rb"
        task load: :_load_communard do
          @_communard_commands.load_schema
        end

        desc "Dumps the schema to db/schema.rb"
        task dump: :_load_communard do
          @_communard_commands.dump_schema
        end

      end
    end

  end
end
