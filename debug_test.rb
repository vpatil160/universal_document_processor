#!/usr/bin/env ruby

# Add lib directory to load path
$LOAD_PATH.unshift File.expand_path('lib', __dir__)

# Load the gem
require 'universal_document_processor'
require 'tempfile'

# Create a simple text file
txt_file = Tempfile.new(['test', '.txt'])
txt_file.write("This is a sample text file.\nIt has multiple lines.\nUsed for testing.")
txt_file.close

puts "Testing text file: #{txt_file.path}"

begin
  puts "Processing file..."
  result = UniversalDocumentProcessor.process(txt_file.path)
  
  puts "Result keys: #{result.keys}"
  puts "Result type: #{result.class}"
  
  if result.is_a?(Hash)
    result.each do |key, value|
      puts "#{key}: #{value.class} - #{value.to_s[0..100]}..."
    end
  end
  
rescue => e
  puts "Error: #{e.class} - #{e.message}"
  puts e.backtrace.first(5)
end

txt_file.unlink 