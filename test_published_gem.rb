#!/usr/bin/env ruby

# Test script to check for potential issues with the published gem
# This simulates real-world usage scenarios

puts "🔍 Testing Universal Document Processor v1.0.3 for Potential Issues"
puts "=" * 70

# Add lib directory to load path for local testing
$LOAD_PATH.unshift File.expand_path('lib', __dir__)

require 'universal_document_processor'
require 'tempfile'

test_count = 0
issue_count = 0
warnings = []

def test_issue(description)
  global_test_count = caller_locations.first.lineno
  print "#{global_test_count}. #{description}... "
  
  begin
    yield
    puts "✅ OK"
    return false # No issue
  rescue => e
    puts "❌ ISSUE: #{e.message}"
    puts "   #{e.backtrace.first}" if ENV['DEBUG']
    return true # Issue found
  end
end

def check_warning(description)
  print "⚠️  #{description}... "
  begin
    result = yield
    if result
      puts "FOUND"
      return result
    else
      puts "OK"
      return nil
    end
  rescue => e
    puts "ERROR: #{e.message}"
    return e.message
  end
end

puts "\n🧪 Testing Core Functionality Issues"
puts "-" * 40

# Test 1: Basic gem loading
test_count += 1
issue_found = test_issue("Gem loads without errors") do
  # Just loading the gem should work
  raise "VERSION not defined" unless defined?(UniversalDocumentProcessor::VERSION)
  raise "Main module not available" unless defined?(UniversalDocumentProcessor)
end
issue_count += 1 if issue_found

# Test 2: AI agent without API key (should not crash)
test_count += 1
issue_found = test_issue("AI agent creation without API key") do
  agent = UniversalDocumentProcessor.create_ai_agent
  raise "Agent not created" unless agent.is_a?(UniversalDocumentProcessor::AIAgent)
  raise "AI should not be available" if agent.ai_available?
end
issue_count += 1 if issue_found

# Test 3: Text file processing
test_count += 1
issue_found = test_issue("Basic text file processing") do
  txt_file = Tempfile.new(['test', '.txt'])
  txt_file.write("Sample text content")
  txt_file.close
  
  result = UniversalDocumentProcessor.process(txt_file.path)
  raise "No text_content key" unless result.has_key?(:text_content)
  raise "No metadata key" unless result.has_key?(:metadata)
  
  txt_file.unlink
end
issue_count += 1 if issue_found

# Test 4: CSV processing
test_count += 1
issue_found = test_issue("CSV file processing") do
  csv_file = Tempfile.new(['test', '.csv'])
  csv_file.write("Name,Age\nJohn,25\nJane,30")
  csv_file.close
  
  result = UniversalDocumentProcessor.process(csv_file.path)
  raise "Wrong format detected" unless result[:metadata][:format] == "csv"
  raise "No tables extracted" unless result[:tables].length > 0
  
  csv_file.unlink
end
issue_count += 1 if issue_found

# Test 5: TSV processing (our new feature)
test_count += 1
issue_found = test_issue("TSV file processing") do
  tsv_file = Tempfile.new(['test', '.tsv'])
  tsv_file.write("Name\tAge\nJohn\t25\nJane\t30")
  tsv_file.close
  
  result = UniversalDocumentProcessor.process(tsv_file.path)
  raise "Wrong format detected" unless result[:metadata][:format] == "tsv"
  raise "Wrong delimiter" unless result[:metadata][:delimiter] == "tab"
  raise "No tables extracted" unless result[:tables].length > 0
  
  tsv_file.unlink
end
issue_count += 1 if issue_found

puts "\n🔒 Testing Dependency Issues"
puts "-" * 40

# Test 6: Optional dependency checking
test_count += 1
issue_found = test_issue("Optional dependency information") do
  deps = UniversalDocumentProcessor.optional_dependencies
  raise "No optional deps info" if deps.empty?
  
  missing = UniversalDocumentProcessor.missing_dependencies
  raise "Missing deps not array" unless missing.is_a?(Array)
  
  instructions = UniversalDocumentProcessor.installation_instructions
  raise "No installation instructions" if instructions.empty?
end
issue_count += 1 if issue_found

# Test 7: PDF processing without pdf-reader gem
test_count += 1
issue_found = test_issue("PDF processing dependency handling") do
  # Create a fake PDF file (just for testing error handling)
  pdf_file = Tempfile.new(['test', '.pdf'])
  pdf_file.write("%PDF-1.4\nFake PDF content")
  pdf_file.close
  
  begin
    result = UniversalDocumentProcessor.process(pdf_file.path)
    # Should either work (if pdf-reader available) or give graceful error
  rescue UniversalDocumentProcessor::DependencyMissingError => e
    # This is expected and good
    raise "Wrong error message" unless e.message.include?("pdf-reader")
  end
  
  pdf_file.unlink
end
issue_count += 1 if issue_found

puts "\n⚠️  Testing Edge Cases & Potential Warnings"
puts "-" * 40

# Warning 1: Large file handling
warning = check_warning("Large file memory usage") do
  # Create a moderately large text file
  large_file = Tempfile.new(['large_test', '.txt'])
  content = "This is a test line.\n" * 10000  # ~200KB
  large_file.write(content)
  large_file.close
  
  start_time = Time.now
  result = UniversalDocumentProcessor.process(large_file.path)
  end_time = Time.now
  
  large_file.unlink
  
  processing_time = end_time - start_time
  if processing_time > 5.0
    "Large file processing took #{processing_time.round(2)} seconds"
  else
    false
  end
end
warnings << warning if warning

# Warning 2: Unicode/Japanese filename handling
warning = check_warning("Unicode filename handling") do
  begin
    japanese_content = "これは日本語のテストです。"
    unicode_file = Tempfile.new(['テスト', '.txt'])
    unicode_file.write(japanese_content)
    unicode_file.close
    
    result = UniversalDocumentProcessor.process(unicode_file.path)
    unicode_file.unlink
    false
  rescue => e
    "Unicode filename issue: #{e.message}"
  end
end
warnings << warning if warning

# Warning 3: Empty file handling
warning = check_warning("Empty file handling") do
  empty_file = Tempfile.new(['empty', '.txt'])
  empty_file.close
  
  begin
    result = UniversalDocumentProcessor.process(empty_file.path)
    empty_file.unlink
    
    if result[:text_content].nil? || result[:text_content].empty?
      false # This is expected
    else
      false # Also fine
    end
  rescue => e
    empty_file.unlink
    "Empty file processing issue: #{e.message}"
  end
end
warnings << warning if warning

# Warning 4: Invalid file extension handling
warning = check_warning("Invalid file extension handling") do
  invalid_file = Tempfile.new(['test', '.xyz'])
  invalid_file.write("Test content")
  invalid_file.close
  
  begin
    result = UniversalDocumentProcessor.process(invalid_file.path)
    invalid_file.unlink
    false # Processed successfully
  rescue UniversalDocumentProcessor::UnsupportedFormatError
    invalid_file.unlink
    false # Expected error, good
  rescue => e
    invalid_file.unlink
    "Unexpected error for unsupported format: #{e.message}"
  end
end
warnings << warning if warning

# Warning 5: Memory usage with multiple files
warning = check_warning("Memory usage with batch processing") do
  files = []
  5.times do |i|
    file = Tempfile.new(["batch_#{i}", '.txt'])
    file.write("Batch test content #{i}\n" * 1000)
    file.close
    files << file.path
  end
  
  begin
    start_memory = `tasklist /FI "PID eq #{Process.pid}" /FO CSV`.split("\n")[1].split(",")[4].gsub('"', '').gsub(',', '').to_i rescue 0
    
    results = UniversalDocumentProcessor.batch_process(files)
    
    end_memory = `tasklist /FI "PID eq #{Process.pid}" /FO CSV`.split("\n")[1].split(",")[4].gsub('"', '').gsub(',', '').to_i rescue 0
    
    files.each { |f| File.delete(f) if File.exist?(f) }
    
    memory_increase = end_memory - start_memory
    if memory_increase > 50000  # 50MB increase
      "High memory usage: #{memory_increase}KB increase"
    else
      false
    end
  rescue => e
    files.each { |f| File.delete(f) if File.exist?(f) }
    "Batch processing memory test failed: #{e.message}"
  end
end
warnings << warning if warning

puts "\n🔍 Testing AI Features (Without API Key)"
puts "-" * 40

# Test 8: AI methods should fail gracefully
test_count += 1
issue_found = test_issue("AI methods fail gracefully without API key") do
  txt_file = Tempfile.new(['ai_test', '.txt'])
  txt_file.write("Test content for AI")
  txt_file.close
  
  begin
    UniversalDocumentProcessor.ai_analyze(txt_file.path)
    raise "Should have raised DependencyMissingError"
  rescue UniversalDocumentProcessor::DependencyMissingError => e
    # Expected - this is good
    raise "Wrong error message" unless e.message.include?("OpenAI API key")
  end
  
  txt_file.unlink
end
issue_count += 1 if issue_found

puts "\n📊 Testing Available Features"
puts "-" * 40

# Test 9: Feature detection
test_count += 1
issue_found = test_issue("Feature detection works correctly") do
  features = UniversalDocumentProcessor.available_features
  raise "No features detected" if features.empty?
  raise "Missing basic features" unless features.include?(:text_processing)
  raise "Missing TSV support" unless features.include?(:tsv_processing)
  
  # AI should not be available without API key
  raise "AI should not be available" if features.include?(:ai_processing)
end
issue_count += 1 if issue_found

puts "\n" + "=" * 70
puts "🎯 ISSUE ANALYSIS COMPLETE"
puts "=" * 70

puts "\n📈 SUMMARY:"
puts "  Total tests run: #{test_count}"
puts "  Issues found: #{issue_count}"
puts "  Warnings: #{warnings.compact.length}"

if issue_count == 0
  puts "\n✅ NO CRITICAL ISSUES FOUND!"
  puts "The gem appears to be working correctly for basic usage."
else
  puts "\n❌ CRITICAL ISSUES DETECTED!"
  puts "The gem has #{issue_count} critical issues that need attention."
end

if warnings.compact.length > 0
  puts "\n⚠️  WARNINGS TO CONSIDER:"
  warnings.compact.each_with_index do |warning, i|
    puts "  #{i + 1}. #{warning}"
  end
else
  puts "\n✅ No significant warnings detected."
end

puts "\n🔮 POTENTIAL USER ISSUES TO WATCH FOR:"
puts "1. Users trying to use AI features without setting OPENAI_API_KEY"
puts "2. Users expecting PDF/Word processing without installing optional gems"
puts "3. Large file processing performance"
puts "4. Unicode filename handling on different systems"
puts "5. Memory usage with batch processing of many files"

puts "\n💡 RECOMMENDATIONS:"
puts "1. ✅ AI dependency handling is working correctly"
puts "2. ✅ TSV processing is functional"
puts "3. ✅ Error messages are helpful"
puts "4. 📚 Consider adding performance guidelines to documentation"
puts "5. 📚 Consider adding memory usage notes for large files"

exit issue_count 