require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new

desc "Run tests and linting"
task default: %i[spec rubocop]

desc "Build the gem"
task :build do
  system "gem build universal_document_processor.gemspec"
end

desc "Release the gem"
task :release do
  system "gem build universal_document_processor.gemspec"
  system "gem push universal_document_processor-*.gem"
end

desc "Install the gem locally"
task :install do
  system "gem build universal_document_processor.gemspec"
  system "gem install universal_document_processor-*.gem"
end

desc "Clean build artifacts"
task :clean do
  system "rm -f *.gem"
end

desc "Generate documentation"
task :doc do
  system "yard doc"
end 