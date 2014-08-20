# Communard

Communard adds some conventions from [ActiveRecord][ar] to [Sequel][sq].

This means you can use `config/database.yml` and `db/migrate` again, so you
don't have to change deployment scripts that are made for ActiveRecord.

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

### Connecting to the database

To get a database connection:

``` ruby
DB = Communard.connect
```

The `DB` object will be familiar to you if you've ever read the Sequel documentation.

Note: Communard doesn't remember your connection.

### Rake integration

To add most Rake tasks, add this to your `Rakefile` or to `lib/tasks/communard.rake`:

``` ruby
require "communard/rake"
Communard::Rake.add_tasks
```

This will add the most used rake tasks, like `db:create`, `db:migrate`, and `db:setup`.

To see them all:

```
$ rake -T db
```

### Migrations

To generate a migration:

```
$ bundle exec communard --generate-migration create_posts
```

Communard doesn't support more arguments, like the Rails generator does. You'll
have to edit the generated migration file yourself.

### Configuration

There are a couple of configuration options available. They can be set by giving
a block to `connect` or `add_tasks`. Under normal circumstances you don't need
to set them.

``` ruby
DB = Communard.connect { |config|
  config.root        = Rails.root
  config.logger      = Rails.logger
  config.environment = Rails.env.to_s
}
```

## Contributing

1. Fork it ( https://github.com/yourkarma/communard/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

[ar]: http://rubyonrails.org
[sq]: http://sequel.jeremyevans.net
