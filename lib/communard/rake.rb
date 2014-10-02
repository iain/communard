require "communard"

module Communard
  class Rake

    extend ::Rake::DSL if defined?(::Rake::DSL)

    def self.add_tasks(ns = :db, &block)

      namespace ns do
        task :_load_communard do
          @_communard_context = Communard.context(&block)
        end

        desc "Creates the database, migrate the schema, and loads seed data"
        task :setup => [:create, :migrate, :seed, "db:test:prepare"]

        desc "Creates the database"
        task :create => :_load_communard do
          @_communard_context.create_database
        end

        desc "Drops the database"
        task :drop => :_load_communard do
          @_communard_context.drop_database
        end

        desc "Drops and creates the database"
        task :reset => [:drop, :setup]

        desc "Migrate the database"
        task :migrate => :_load_communard do
          target = ENV["VERSION"] || ENV["TARGET"]
          @_communard_context.migrate(target: target)
        end

        desc "Load the seed data from db/seeds.rb"
        task :seed => :_load_communard do
          @_communard_context.seed
        end

        desc "Rolls the schema back to the previous version"
        task :rollback => :_load_communard do
          step = Integer(ENV["STEP"] || 1)
          @_communard_context.rollback(step: step)
        end

        namespace :test do
          desc "Cleans the test database"
          task :prepare => :_load_communard do
            context = @_communard_context
            context.drop_database(env: "test")
            context.create_database(env: "test")
            context.migrate(env: "test")
          end
        end

        namespace :migrate do

          desc "Redo the last migration"
          task :redo => :_load_communard do
            context = @_communard_context
            context.rollback
            context.migrate
          end

          desc "Display status of migrations"
          task :status, :_load_communard do
            @_communard_context.status
          end
        end

        namespace :schema do

          desc "Load the schema from db/schema.rb"
          task :load => :_load_communard do
            @_communard_context.load_schema
          end

          desc "Dumps the schema to db/schema.rb"
          task :dump => :_load_communard do
            @_communard_context.dump_schema
          end

        end

      end
    end

  end
end
