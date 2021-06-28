#!/usr/bin/env rake

# rubocop rake task
desc 'Chef cookbook style linting'
task :cookstyle do
  sh 'cookstyle'
end

desc 'Run ChefSpec unit tests'
task :unit do
  # chefspec task against spec/*_spec.rb
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:unit) do |t|
    t.rspec_opts = '--color --format progress'
  end
end

desc 'Run test kitchen integration tests'
task :integration, [:os] do |_t, args|
  require 'kitchen'
  config = {
    loader: Kitchen::Loader::YAML.new(project_config: '.kitchen.dokken.yml'),
  }
  instances = Kitchen::Config.new(config).instances
  instances.get_all(/#{args.os}/).each(&:test)
end

task lint: %w(cookstyle)
task default: %w(lint unit)
