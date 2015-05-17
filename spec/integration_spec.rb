require "yaml"

RSpec.describe "Integration", type: :aruba do

  example "SQLite" do
    run_tests(
      "adapter"  => "sqlite",
      "database" => "db/test.sqlite3",
      "pool"     => 5,
      "timeout"  => 5000,
    )
  end

  example "PostgreSQL" do
    run_tests(
      "adapter"  => "postgres",
      "database" => "communard_test",
      "pool"     => 5,
      "timeout"  => 5000,
    )
  end

  example "MySQL" do
    run_tests(
      "adapter"  => "mysql2",
      "database" => "communard_test",
      "username" => "root",
      "pool"     => 5,
      "timeout"  => 5000,
    )
  end


  def run_tests(database_config)

    write_file "config/database.yml", { "development" => database_config }.to_yaml

    write_file "Rakefile", <<-FILE.gsub(/^\s{6}/, "")
      $LOAD_PATH.unshift(File.expand_path("../../../lib", __FILE__))
      require "yaml"
      require "communard/rake"
      Communard::Rake.add_tasks
    FILE

    run_simple "bundle exec communard --generate-migration create_posts"

    file = Dir[absolute_path("db/migrate/*_create_posts.rb")].first

    expect(File.read(file)).to eq <<-FILE.gsub(/^\s{6}/, "").chomp
      Sequel.migration do
        change do
        end
      end
    FILE

    write_file file, <<-FILE.gsub(/^\s{6}/, "")
      Sequel.migration do
        change do
          create_table :posts do
            primary_key :id
            String :name
          end
        end
      end
    FILE

    run_simple "rake db:drop"

    run_simple "rake db:create"

    run_simple "rake db:migrate"

    write_file "app.rb", <<-FILE.gsub(/^\s{6}/, "")
      $LOAD_PATH.unshift(File.expand_path("../../../lib", __FILE__))
      require "yaml"
      require "communard"

      db = Communard.connect
      posts = db[:posts]

      4.times do
        posts.insert(name: "hello world")
      end

      puts "Post count: '\#{posts.count}'"
    FILE

    run_simple "ruby app.rb"

    assert_partial_output("Post count: '4'", all_stdout)
  end


end
