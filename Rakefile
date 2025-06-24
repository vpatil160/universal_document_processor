require 'rake/testtask'
require 'bundler/gem_tasks'

# Default task
task default: :test

# Test task
Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/test_*.rb']
  t.verbose = true
end

# Individual test tasks
Rake::TestTask.new(:test_core) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/test_universal_document_processor.rb']
  t.verbose = true
end

Rake::TestTask.new(:test_ai) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/test_ai_agent.rb']
  t.verbose = true
end

Rake::TestTask.new(:test_processors) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/test_processors.rb']
  t.verbose = true
end

# Coverage task (if simplecov is available)
desc "Run tests with coverage"
task :coverage do
  ENV['COVERAGE'] = 'true'
  Rake::Task[:test].invoke
end

# Lint task (if rubocop is available)
desc "Run RuboCop"
task :lint do
  begin
    require 'rubocop/rake_task'
    RuboCop::RakeTask.new
  rescue LoadError
    puts "RuboCop not available. Install it with: gem install rubocop"
  end
end

# Documentation task
desc "Generate documentation"
task :doc do
  system "yard doc"
end

# Clean task
desc "Clean up generated files"
task :clean do
  FileUtils.rm_rf('coverage')
  FileUtils.rm_rf('doc')
  FileUtils.rm_rf('pkg')
  FileUtils.rm_f('Gemfile.lock')
end

# Install dependencies
desc "Install dependencies"
task :install do
  system "bundle install"
end

# Quality check task
desc "Run all quality checks"
task quality: [:test, :lint]

# CI task
desc "Run CI tasks"
task ci: [:install, :test]

# Development setup
desc "Setup development environment"
task :setup do
  puts "Setting up development environment..."
  Rake::Task[:install].invoke
  puts "Development environment ready!"
  puts ""
  puts "Available tasks:"
  puts "  rake test        - Run all tests"
  puts "  rake test_core   - Run core functionality tests"
  puts "  rake test_ai     - Run AI agent tests"
  puts "  rake test_processors - Run processor tests"
  puts "  rake coverage    - Run tests with coverage"
  puts "  rake lint        - Run RuboCop linting"
  puts "  rake doc         - Generate documentation"
  puts "  rake clean       - Clean up generated files"
  puts ""
  puts "To run tests with AI features, set OPENAI_API_KEY environment variable"
end

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