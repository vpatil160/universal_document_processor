#!/usr/bin/env ruby

# Performance and Memory Usage Analysis for Universal Document Processor
# This test checks if we need to add performance guidelines and memory usage documentation

puts "🚀 Performance & Memory Analysis - Universal Document Processor"
puts "=" * 70

$LOAD_PATH.unshift File.expand_path('lib', __dir__)
require 'universal_document_processor'
require 'tempfile'
require 'benchmark'

# Helper to get memory usage (Windows-specific)
def get_memory_usage
  begin
    result = `tasklist /FI "PID eq #{Process.pid}" /FO CSV 2>nul`
    if result && !result.empty?
      lines = result.split("\n")
      if lines.length > 1
        memory_str = lines[1].split(",")[4].gsub('"', '').gsub(',', '')
        return memory_str.to_i # KB
      end
    end
  rescue
    # Fallback for non-Windows or error cases
  end
  return 0
end

def format_memory(kb)
  if kb > 1024
    "#{(kb / 1024.0).round(1)} MB"
  else
    "#{kb} KB"
  end
end

def create_test_file(size_description, content_generator)
  file = Tempfile.new(['perf_test', '.txt'])
  content = content_generator.call
  file.write(content)
  file.close
  
  actual_size = File.size(file.path)
  puts "  📁 Created #{size_description}: #{format_memory(actual_size / 1024)} (#{file.path})"
  
  return file, actual_size
end

issues_found = []
performance_concerns = []

puts "\n📊 PERFORMANCE TESTING"
puts "-" * 50

# Test 1: Small file performance (baseline)
puts "\n1️⃣ Small File Performance (Baseline)"
small_file, small_size = create_test_file("small file", -> { "Hello World!\n" * 100 })

start_memory = get_memory_usage
time_taken = Benchmark.realtime do
  result = UniversalDocumentProcessor.process(small_file.path)
end
end_memory = get_memory_usage

puts "  ⏱️  Processing time: #{(time_taken * 1000).round(2)} ms"
puts "  🧠 Memory change: #{format_memory(end_memory - start_memory)}"

small_file.unlink
baseline_time = time_taken

# Test 2: Medium file performance
puts "\n2️⃣ Medium File Performance (1MB)"
medium_file, medium_size = create_test_file("medium file", -> { "This is a test line with some content.\n" * 25000 })

start_memory = get_memory_usage
time_taken = Benchmark.realtime do
  result = UniversalDocumentProcessor.process(medium_file.path)
end
end_memory = get_memory_usage

puts "  ⏱️  Processing time: #{(time_taken * 1000).round(2)} ms"
puts "  🧠 Memory change: #{format_memory(end_memory - start_memory)}"
puts "  📈 Speed ratio: #{(time_taken / baseline_time).round(1)}x slower than baseline"

if time_taken > 2.0
  performance_concerns << "Medium files (1MB) take #{time_taken.round(2)} seconds to process"
end

medium_file.unlink

# Test 3: Large file performance
puts "\n3️⃣ Large File Performance (5MB)"
large_file, large_size = create_test_file("large file", -> { "This is a longer test line with more content to simulate real documents.\n" * 75000 })

start_memory = get_memory_usage
time_taken = Benchmark.realtime do
  result = UniversalDocumentProcessor.process(large_file.path)
end
end_memory = get_memory_usage

puts "  ⏱️  Processing time: #{(time_taken * 1000).round(2)} ms"
puts "  🧠 Memory change: #{format_memory(end_memory - start_memory)}"
puts "  📈 Speed ratio: #{(time_taken / baseline_time).round(1)}x slower than baseline"

if time_taken > 10.0
  performance_concerns << "Large files (5MB) take #{time_taken.round(2)} seconds to process"
end

if (end_memory - start_memory) > 100000  # 100MB
  performance_concerns << "Large files use #{format_memory(end_memory - start_memory)} of memory"
end

large_file.unlink

puts "\n💾 MEMORY USAGE TESTING"
puts "-" * 50

# Test 4: Memory usage with multiple files
puts "\n4️⃣ Batch Processing Memory Test"
files = []
file_sizes = []

5.times do |i|
  file, size = create_test_file("batch file #{i+1}", -> { "Batch processing test content line #{i}.\n" * 5000 })
  files << file.path
  file_sizes << size
end

total_file_size = file_sizes.sum
puts "  📦 Total file size: #{format_memory(total_file_size / 1024)}"

start_memory = get_memory_usage
time_taken = Benchmark.realtime do
  results = UniversalDocumentProcessor.batch_process(files)
end
end_memory = get_memory_usage

memory_used = end_memory - start_memory
puts "  ⏱️  Batch processing time: #{(time_taken * 1000).round(2)} ms"
puts "  🧠 Memory used: #{format_memory(memory_used)}"
puts "  📊 Memory efficiency: #{(memory_used.to_f / (total_file_size / 1024)).round(2)}x file size"

if memory_used > (total_file_size / 1024) * 3  # More than 3x file size
  performance_concerns << "Batch processing uses #{(memory_used.to_f / (total_file_size / 1024)).round(1)}x the file size in memory"
end

# Cleanup
files.each { |f| File.delete(f) if File.exist?(f) }

# Test 5: CSV/TSV processing performance
puts "\n5️⃣ Structured Data Processing Performance"

# Large CSV test
csv_content = "Name,Age,Email,Department,Salary,Location,Phone\n"
csv_content += 10000.times.map { |i| "User#{i},#{20+i%50},user#{i}@example.com,Dept#{i%10},#{30000+i*10},City#{i%100},555-#{i.to_s.rjust(4, '0')}" }.join("\n")

csv_file = Tempfile.new(['large', '.csv'])
csv_file.write(csv_content)
csv_file.close

csv_size = File.size(csv_file.path)
puts "  📊 Large CSV size: #{format_memory(csv_size / 1024)}"

start_memory = get_memory_usage
time_taken = Benchmark.realtime do
  result = UniversalDocumentProcessor.process(csv_file.path)
end
end_memory = get_memory_usage

puts "  ⏱️  CSV processing time: #{(time_taken * 1000).round(2)} ms"
puts "  🧠 Memory change: #{format_memory(end_memory - start_memory)}"

if time_taken > 5.0
  performance_concerns << "Large CSV files (#{format_memory(csv_size / 1024)}) take #{time_taken.round(2)} seconds"
end

csv_file.unlink

# Test 6: Unicode content performance
puts "\n6️⃣ Unicode Content Performance"
unicode_content = "これは日本語のテストです。🌟 This includes emoji and special characters: áéíóú, ñ, ç, ü\n" * 5000

unicode_file = Tempfile.new(['unicode', '.txt'])
unicode_file.write(unicode_content)
unicode_file.close

start_memory = get_memory_usage
time_taken = Benchmark.realtime do
  result = UniversalDocumentProcessor.process(unicode_file.path)
end
end_memory = get_memory_usage

puts "  ⏱️  Unicode processing time: #{(time_taken * 1000).round(2)} ms"
puts "  🧠 Memory change: #{format_memory(end_memory - start_memory)}"

unicode_file.unlink

puts "\n" + "=" * 70
puts "🎯 PERFORMANCE & MEMORY ANALYSIS RESULTS"
puts "=" * 70

puts "\n📈 PERFORMANCE CONCERNS FOUND:"
if performance_concerns.empty?
  puts "✅ No significant performance issues detected!"
  puts "   The gem performs well within reasonable limits."
else
  performance_concerns.each_with_index do |concern, i|
    puts "⚠️  #{i + 1}. #{concern}"
  end
end

puts "\n📚 DOCUMENTATION RECOMMENDATIONS:"

puts "\n4️⃣ Performance Guidelines Needed:"
guidelines_needed = []

if performance_concerns.any? { |c| c.include?("seconds") }
  guidelines_needed << "Processing time expectations for different file sizes"
  guidelines_needed << "Recommended file size limits for real-time processing"
end

if performance_concerns.any? { |c| c.include?("memory") }
  guidelines_needed << "Memory usage patterns and optimization tips"
  guidelines_needed << "Best practices for batch processing large files"
end

guidelines_needed << "Performance comparison between different file formats"
guidelines_needed << "Optimization tips for production environments"

if guidelines_needed.any?
  puts "📋 Suggested documentation additions:"
  guidelines_needed.each_with_index do |guideline, i|
    puts "   #{i + 1}. #{guideline}"
  end
else
  puts "✅ Current performance is good - minimal documentation needed"
end

puts "\n5️⃣ Memory Usage Documentation Needed:"
memory_docs_needed = []

memory_docs_needed << "Expected memory usage patterns (typically 2-3x file size)"
memory_docs_needed << "Memory-efficient processing tips for large files"
memory_docs_needed << "Batch processing memory considerations"
memory_docs_needed << "When to process files individually vs. in batches"

puts "📋 Suggested memory usage documentation:"
memory_docs_needed.each_with_index do |doc, i|
  puts "   #{i + 1}. #{doc}"
end

puts "\n💡 SPECIFIC RECOMMENDATIONS:"
puts "1. Add a PERFORMANCE.md file with benchmarks and guidelines"
puts "2. Include memory usage examples in README"
puts "3. Add performance tips to method documentation"
puts "4. Consider adding a performance_info method to the gem"
puts "5. Document recommended file size limits for different use cases"

puts "\n🎯 CONCLUSION:"
if performance_concerns.length > 2
  puts "❌ Performance documentation is NEEDED - several concerns found"
  exit 1
elsif performance_concerns.length > 0
  puts "⚠️  Performance documentation would be HELPFUL - some concerns found"
  exit 2
else
  puts "✅ Performance is good, but documentation would still be valuable for users"
  exit 0
end 