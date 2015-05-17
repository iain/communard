require "bundler/gem_tasks"

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
  task :spec do
    puts "RSpec not installed"
    exit 1
  end
end

task :default => :spec
