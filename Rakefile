require 'rubygems'
require 'rake'

require 'rubygems/tasks'
Gem::Tasks.new

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new
task :default => :spec

require 'yard'
YARD::Rake::YardocTask.new
