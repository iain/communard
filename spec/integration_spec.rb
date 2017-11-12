require "yaml"

RSpec.describe "Integration", type: :aruba do

  example "SQLite" do
    run_tests("sqlite://db/test.sqlite3")
  end

  example "PostgreSQL" do
    run_tests("postgresql://localhost:5432/communard_test")
  end

  example "MySQL" do
    run_tests("mysql2://root@localhost:3306/communard_test")
  end

  def run_tests(database_config)
    write_file "Rakefile", <<-FILE.gsub(/^\s{6}/, "")
      $LOAD_PATH.unshift(File.expand_path("../../../lib", __FILE__))
      require "communard/rake"
      namespace :db do
        Communard::Rake.add_tasks("#{database_config}")
      end
    FILE

    run_simple "bundle exec communard migration create_posts"

    glob = Dir[expand_path("db/migrate/*_create_posts.rb")]
    file = glob.first

    expect(File.read(file)).to eq "Sequel.migration do\n\n  change do\n  end\n\nend\n"

    write_file "db/migrate/#{File.basename(file)}", <<-FILE.gsub(/^\s{6}/, "")
      Sequel.migration do
        change do
          create_table :posts do
            primary_key :id
            String :name
          end
        end
      end
    FILE

    run_simple "bundle exec rake db:drop"

    run_simple "bundle exec rake db:create"

    run_simple "bundle exec rake db:migrate"
  end

end
