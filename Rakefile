#!/usr/bin/env rake
require "bundler/gem_tasks"
require "rspec/core/rake_task"

task :default => [:rspec]

RSpec::Core::RakeTask.new(:rspec)

namespace :rcov do
  RSpec::Core::RakeTask.new(:rspec) do |t|
    t.rcov = true
    t.rcov_opts = [%{--exclude "spec/*,gems/*"}]
  end
end
