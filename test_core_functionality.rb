#!/usr/bin/env ruby

# Add lib directory to load path
$LOAD_PATH.unshift File.expand_path('lib', __dir__)

# Load the gem
require 'universal_document_processor'
require 'tempfile'

puts "Testing Core Functionality"
puts "=" * 50

test_count = 0
passed_count = 0

def test(description)
  global_test_count = caller_locations.first.lineno
  print "#{global_test_count}. #{description}... "
  
  begin
    yield
    puts "✓ PASS"
    return true
  rescue => e
    puts "✗ FAIL: #{e.message}"
    puts "   #{e.backtrace.first}" if ENV['DEBUG']
    return false
  end
end

# Create sample files for testing
puts "\nCreating sample files..."

# Text file
txt_file = Tempfile.new(['test', '.txt'])
txt_file.write("This is a sample text file.\nIt has multiple lines.\nUsed for testing.")
txt_file.close

# CSV file
csv_file = Tempfile.new(['test', '.csv'])
csv_file.write("Name,Age,City\nJohn,25,New York\nJane,30,Los Angeles\nBob,35,Chicago")
csv_file.close

# TSV file
tsv_file = Tempfile.new(['test', '.tsv'])
tsv_file.write("Name\tAge\tCity\nJohn\t25\tNew York\nJane\t30\tLos Angeles\nBob\t35\tChicago")
tsv_file.close

# JSON file
json_file = Tempfile.new(['test', '.json'])
json_file.write('{"name": "Test Document", "type": "sample", "data": [1, 2, 3, 4, 5]}')
json_file.close

# XML file
xml_file = Tempfile.new(['test', '.xml'])
xml_file.write(<<~XML)
  <?xml version="1.0" encoding="UTF-8"?>
  <document>
    <title>Sample XML Document</title>
    <content>This is a sample XML file for testing.</content>
  </document>
XML
xml_file.close

puts "Sample files created successfully!"

# Run tests
puts "\nRunning Core Tests:"
puts "-" * 30

# Test 1: Version number
test_count += 1
passed = test("Version number is defined") do
  version = UniversalDocumentProcessor::VERSION
  raise "Version is nil" if version.nil?
  raise "Version format invalid" unless version.match?(/\d+\.\d+\.\d+/)
end
passed_count += 1 if passed

# Test 2: Text file processing
test_count += 1
passed = test("Text file processing") do
  result = UniversalDocumentProcessor.process(txt_file.path)
  raise "Result is not a hash" unless result.is_a?(Hash)
  raise "Missing text key" unless result.has_key?(:text)
  raise "Missing metadata key" unless result.has_key?(:metadata)
  raise "Text content incorrect" unless result[:text].include?("sample text file")
  raise "Format incorrect" unless result[:metadata][:format] == "txt"
end
passed_count += 1 if passed

# Test 3: Text extraction
test_count += 1
passed = test("Text extraction method") do
  text = UniversalDocumentProcessor.extract_text(txt_file.path)
  raise "Text is not a string" unless text.is_a?(String)
  raise "Text content missing" unless text.include?("sample text file")
end
passed_count += 1 if passed

# Test 4: Metadata extraction
test_count += 1
passed = test("Metadata extraction") do
  metadata = UniversalDocumentProcessor.get_metadata(txt_file.path)
  raise "Metadata is not a hash" unless metadata.is_a?(Hash)
  raise "Format missing" unless metadata[:format] == "txt"
  raise "File size missing" unless metadata[:file_size] > 0
end
passed_count += 1 if passed

# Test 5: CSV processing
test_count += 1
passed = test("CSV file processing") do
  result = UniversalDocumentProcessor.process(csv_file.path)
  raise "Result is not a hash" unless result.is_a?(Hash)
  raise "Missing tables key" unless result.has_key?(:tables)
  raise "Format incorrect" unless result[:metadata][:format] == "csv"
  raise "Delimiter incorrect" unless result[:metadata][:delimiter] == "comma"
  raise "No tables found" unless result[:tables].length > 0
end
passed_count += 1 if passed

# Test 6: TSV processing
test_count += 1
passed = test("TSV file processing") do
  result = UniversalDocumentProcessor.process(tsv_file.path)
  raise "Result is not a hash" unless result.is_a?(Hash)
  raise "Missing tables key" unless result.has_key?(:tables)
  raise "Format incorrect" unless result[:metadata][:format] == "tsv"
  raise "Delimiter incorrect" unless result[:metadata][:delimiter] == "tab"
  raise "No tables found" unless result[:tables].length > 0
end
passed_count += 1 if passed

# Test 7: JSON processing
test_count += 1
passed = test("JSON file processing") do
  result = UniversalDocumentProcessor.process(json_file.path)
  raise "Result is not a hash" unless result.is_a?(Hash)
  raise "Format incorrect" unless result[:metadata][:format] == "json"
  raise "Text missing" unless result[:text].include?("Test Document")
end
passed_count += 1 if passed

# Test 8: XML processing
test_count += 1
passed = test("XML file processing") do
  result = UniversalDocumentProcessor.process(xml_file.path)
  raise "Result is not a hash" unless result.is_a?(Hash)
  raise "Format incorrect" unless result[:metadata][:format] == "xml"
  raise "Text missing" unless result[:text].include?("Sample XML Document")
end
passed_count += 1 if passed

# Test 9: Batch processing
test_count += 1
passed = test("Batch processing") do
  files = [txt_file.path, csv_file.path, json_file.path]
  results = UniversalDocumentProcessor.batch_process(files)
  raise "Results not array" unless results.is_a?(Array)
  raise "Wrong number of results" unless results.length == 3
  results.each do |result|
    raise "Missing text or error key" unless result.has_key?(:text) || result.has_key?(:error)
  end
end
passed_count += 1 if passed

# Test 10: Available features
test_count += 1
passed = test("Available features check") do
  features = UniversalDocumentProcessor.available_features
  raise "Features not array" unless features.is_a?(Array)
  raise "Missing text processing" unless features.include?(:text_processing)
  raise "Missing CSV processing" unless features.include?(:csv_processing)
  raise "Missing TSV processing" unless features.include?(:tsv_processing)
end
passed_count += 1 if passed

# Test 11: Dependency checking
test_count += 1
passed = test("Dependency availability check") do
  # These may or may not be available, just test the method works
  pdf_available = UniversalDocumentProcessor.dependency_available?(:pdf_reader)
  raise "Dependency check failed" unless [true, false].include?(pdf_available)
end
passed_count += 1 if passed

# Test 12: Text quality analysis
test_count += 1
passed = test("Text quality analysis") do
  analysis = UniversalDocumentProcessor.analyze_text_quality("Clean text")
  raise "Analysis not hash" unless analysis.is_a?(Hash)
  raise "Missing valid_characters" unless analysis.has_key?(:valid_characters)
  raise "Missing invalid_characters" unless analysis.has_key?(:invalid_characters)
end
passed_count += 1 if passed

# Test 13: Text cleaning
test_count += 1
passed = test("Text cleaning") do
  dirty_text = "Clean\x00text"
  clean_text = UniversalDocumentProcessor.clean_text(dirty_text)
  raise "Cleaning failed" if clean_text.include?("\x00")
end
passed_count += 1 if passed

# Test 14: Japanese text detection
test_count += 1
passed = test("Japanese text detection") do
  english = "This is English"
  japanese = "これは日本語"
  raise "English detected as Japanese" if UniversalDocumentProcessor.japanese_text?(english)
  raise "Japanese not detected" unless UniversalDocumentProcessor.japanese_text?(japanese)
end
passed_count += 1 if passed

# Test 15: Optional dependencies info
test_count += 1
passed = test("Optional dependencies information") do
  optional_deps = UniversalDocumentProcessor.optional_dependencies
  raise "Optional deps not hash" unless optional_deps.is_a?(Hash)
  raise "Missing pdf-reader" unless optional_deps.has_key?('pdf-reader')
  
  missing_deps = UniversalDocumentProcessor.missing_dependencies
  raise "Missing deps not array" unless missing_deps.is_a?(Array)
  
  instructions = UniversalDocumentProcessor.installation_instructions
  raise "Instructions not string" unless instructions.is_a?(String)
end
passed_count += 1 if passed

# Test 16: AI availability check (should be false without API key)
test_count += 1
passed = test("AI availability check") do
  ai_available = UniversalDocumentProcessor.ai_available?
  raise "AI should not be available without key" if ai_available
end
passed_count += 1 if passed

# Test 17: Error handling for unsupported format
test_count += 1
passed = test("Error handling for unsupported format") do
  unsupported_file = Tempfile.new(['test', '.unknown'])
  unsupported_file.write("test content")
  unsupported_file.close
  
  begin
    UniversalDocumentProcessor.process(unsupported_file.path)
    raise "Should have raised UnsupportedFormatError"
  rescue UniversalDocumentProcessor::UnsupportedFormatError
    # Expected error
  rescue => e
    raise "Wrong error type: #{e.class}"
  ensure
    unsupported_file.unlink
  end
end
passed_count += 1 if passed

# Clean up
puts "\nCleaning up temporary files..."
[txt_file, csv_file, tsv_file, json_file, xml_file].each do |file|
  file.unlink if File.exist?(file.path)
end

# Results
puts "\n" + "=" * 50
puts "Test Results:"
puts "  Total tests: #{test_count}"
puts "  Passed: #{passed_count}"
puts "  Failed: #{test_count - passed_count}"
puts "  Success rate: #{((passed_count.to_f / test_count) * 100).round(1)}%"

if passed_count == test_count
  puts "\n🎉 All tests passed! Core functionality is working correctly."
  exit 0
else
  puts "\n❌ Some tests failed. Please check the issues above."
  exit 1
end 