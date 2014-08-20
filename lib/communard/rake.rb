require "communard"

module Communard
  class Rake

    extend ::Rake::DSL if defined?(::Rake::DSL)

    def self.add_tasks(ns = :db, &block)

      namespace ns do
        desc "Creates the database, migrate the schema, and loads seed data"
        task :setup => [:create, :migrate, :seed, "db:test:prepare"]

        desc "Creates the database"
        task :create do
          Communard.context(&block).create_database
        end

        desc "Drops the database"
        task :drop do
          Communard.context(&block).drop_database
        end

        desc "Drops and creates the database"
        task :reset => [:drop, :setup]

        desc "Migrate the database"
        task :migrate do
          target = ENV["VERSION"] || ENV["TARGET"]
          Communard.context(&block).migrate(target: target)
        end

        desc "Load the seed data from db/seeds.rb"
        task :seed do
          Communard.context(&block).seed
        end

        desc "Rolls the schema back to the previous version"
        task :rollback do
          step = Integer(ENV["STEP"] || 1)
          Communard.context(&block).rollback(step: step)
        end

        namespace :test do
          desc "Cleans the test database"
          task :prepare do
            context = Communard.context(&block)
            context.drop_database(env: "test")
            context.create_database(env: "test")
            context.migrate(env: "test")
          end
        end

        namespace :migrate do

          desc "Redo the last migration"
          task :redo do
            context = Communard.context(&block)
            context.rollback
            context.migrate
          end

          desc "Display status of migrations"
          task :status do
            Communard.context(&block).status
          end
        end

        namespace :schema do

          desc "Load the schema from db/schema.rb"
          task :load do
            Communard.context(&block).load_schema
          end

          desc "Dumps the schema to db/schema.rb"
          task :dump do
            Communard.context(&block).dump_schema
          end

        end

      end
    end

  end
end
