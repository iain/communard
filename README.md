# Communard

Communard adds some conventions from [ActiveRecord][ar] to [Sequel][sq].

Sequel doesn't provide the exact same functionality as ActiveRecord. Communard
doesn't try to make Sequel quack like ActiveRecord, it just tries to help with
some (not all) setup.

## Installation

Add this line to your application's Gemfile:

```
gem 'communard'
```

And then execute:

```
$ bundle
```

Or install it yourself as:

```
$ gem install communard
```

## Usage

### Rake integration

To add most Rake tasks, add this to your `Rakefile` or to `lib/tasks/communard.rake`:

``` ruby
require "communard/rake"
namespace :db do
  Communard::Rake.add_tasks
end
```

This will add the most used rake tasks, like `db:create`, `db:migrate`, and `db:setup`.

To see them all:

```
$ rake -T db
```

`Communard::Rake.add_tasks` accepts the same configuration options as
`Sequel.connect`. It doesn't immediately make a connection, only when needed.

The default connection string is `ENV["DATABASE_URL"]`, so if you use that,
there is no need to configure anything.

Other configuration options, can be set via a block:

``` ruby
namespace :db do
  Communard::Rake.add_tasks do |config|

    # Change where the application is located, defaults to Dir.pwd
    config.root_path = Dir.pwd

    # Automatically generate schema (default: false)
    config.dump_after_migrating = false

    # Dump types in native format (default) or Ruby (more portable)
    config.same_db = true

    # Add a logger
    config.logger = Logger.new("log/migrations.log")

  end
end
```

Example with using `config/database.yml`:

``` ruby
namespace :db do
  environment = ENV["RAILS_ENV"] || "development"
  all_config = YAML.load_file("config/database.yml")
  Communard::Rake.add_tasks(config.fetch(environment))
end
```

Note about test environment: Communard doesn't try to create a test database
like ActiveRecord does. The only rake task that attempts to do that is
`rake db:test:prepare`. It respawns rake with different environment variables
set. Your mileage may vary.

### Migrations

To generate a migration:

```
$ communard migration create_posts
```

Communard doesn't support more arguments, like the Rails generator does. You'll
have to edit the generated migration file yourself.

Communard supports both timestamps and integer versions. It automatically
detects which type you have. If you have no migrations yet and want to use
timestamps, add `--timestamps`. Read more about how to choose in the
[Sequel docs][tm].

## Contributing

1. Fork it ( https://github.com/iain/communard/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

[ar]: http://rubyonrails.org
[sq]: http://sequel.jeremyevans.net
[tm]: http://sequel.jeremyevans.net/rdoc/files/doc/migration_rdoc.html#label-How+to+choose
