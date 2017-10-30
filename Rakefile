# frozen_string_literal: true

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec)

require "rake/testtask"
Rake::TestTask.new do |t|
  t.libs << "test"
  t.pattern = "test/**/*_test.rb"
end

require "rubocop/rake_task"
desc "Run RuboCop"
RuboCop::RakeTask.new(:rubocop) do |task|
  task.options = ["--display-cop-names"]
end

task default: %w(spec test rubocop)
