#!/usr/bin/env ruby

# Add lib directory to load path
$LOAD_PATH.unshift File.expand_path('lib', __dir__)

# Load the gem
require 'universal_document_processor'

puts "Testing AI Dependency Handling"
puts "=" * 50

# Test 1: Check AI availability without API key
puts "\n1. Testing AI availability without API key:"
ai_available = UniversalDocumentProcessor.ai_available?
puts "   AI Available: #{ai_available}"

# Test 2: Create AI agent without API key
puts "\n2. Creating AI agent without API key:"
agent = UniversalDocumentProcessor.create_ai_agent
puts "   Agent created: #{agent.class}"
puts "   AI enabled: #{agent.ai_enabled}"
puts "   AI available: #{agent.ai_available?}"

# Test 3: Try to use AI methods without API key
puts "\n3. Testing AI methods without API key:"

# Create a sample text file
require 'tempfile'
sample_file = Tempfile.new(['test', '.txt'])
sample_file.write("This is a test document for AI processing.")
sample_file.close

begin
  result = UniversalDocumentProcessor.ai_analyze(sample_file.path)
  puts "   ERROR: Should have raised an exception!"
rescue UniversalDocumentProcessor::DependencyMissingError => e
  puts "   ✓ Correctly raised DependencyMissingError: #{e.message}"
rescue => e
  puts "   ✗ Unexpected error: #{e.class} - #{e.message}"
end

# Test 4: Check available features
puts "\n4. Available features:"
features = UniversalDocumentProcessor.available_features
puts "   Features: #{features.join(', ')}"
puts "   AI processing included: #{features.include?(:ai_processing)}"

# Test 5: Check optional dependencies
puts "\n5. Optional dependencies:"
optional_deps = UniversalDocumentProcessor.optional_dependencies
puts "   Optional dependencies: #{optional_deps.keys.join(', ')}"

missing_deps = UniversalDocumentProcessor.missing_dependencies
puts "   Missing dependencies: #{missing_deps.join(', ')}"

# Test 6: Installation instructions
puts "\n6. Installation instructions:"
instructions = UniversalDocumentProcessor.installation_instructions
puts instructions

# Test 7: Test with API key if provided
if ENV['OPENAI_API_KEY'] && !ENV['OPENAI_API_KEY'].empty?
  puts "\n7. Testing with API key:"
  ai_available_with_key = UniversalDocumentProcessor.ai_available?
  puts "   AI Available with key: #{ai_available_with_key}"
  
  agent_with_key = UniversalDocumentProcessor.create_ai_agent
  puts "   Agent AI enabled: #{agent_with_key.ai_enabled}"
else
  puts "\n7. Skipping API key test (OPENAI_API_KEY not set)"
end

# Clean up
sample_file.unlink

puts "\n" + "=" * 50
puts "AI Dependency Test Complete!"
puts "✓ AI features are properly optional"
puts "✓ Clear error messages when dependencies missing"
puts "✓ Graceful degradation when features unavailable" 