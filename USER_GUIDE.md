# Universal Document Processor - User Guide

Welcome to the Universal Document Processor! This guide will help you get started and make the most of this powerful document processing gem.

## 📋 Table of Contents

1. [Quick Start](#quick-start)
2. [Installation](#installation)
3. [Basic Usage](#basic-usage)
4. [Advanced Features](#advanced-features)
5. [Performance Guidelines](#performance-guidelines)
6. [Memory Usage](#memory-usage)
7. [AI Features](#ai-features)
8. [Troubleshooting](#troubleshooting)
9. [Best Practices](#best-practices)
10. [FAQ](#faq)

## 🚀 Quick Start

```ruby
# Install the gem
gem install universal_document_processor

# Process a document
require 'universal_document_processor'

result = UniversalDocumentProcessor.process('path/to/your/document.txt')
puts result[:text_content]
```

## 📦 Installation

### Basic Installation

```bash
gem install universal_document_processor
```

### Optional Dependencies

The gem works with core features out of the box, but you can install optional dependencies for enhanced functionality:

```bash
# For PDF processing
gem install pdf-reader

# For Word document processing  
gem install docx

# For AI features
gem install ruby-openai
```

### Check Available Features

```ruby
require 'universal_document_processor'

# See what features are available
puts UniversalDocumentProcessor.available_features
# => [:text_processing, :csv_processing, :tsv_processing, :json_processing, :xml_processing]

# Check for missing optional dependencies
puts UniversalDocumentProcessor.missing_dependencies
# => ["pdf-reader", "docx", "ruby-openai"]

# Get installation instructions
puts UniversalDocumentProcessor.installation_instructions
```

## 🔧 Basic Usage

### Processing Single Files

```ruby
require 'universal_document_processor'

# Text files
result = UniversalDocumentProcessor.process('document.txt')
puts result[:text_content]
puts result[:metadata][:format]  # => "txt"

# CSV files
result = UniversalDocumentProcessor.process('data.csv')
puts result[:tables].first[:headers]
puts result[:tables].first[:rows]

# TSV files (Tab-separated values)
result = UniversalDocumentProcessor.process('data.tsv')
puts result[:metadata][:delimiter]  # => "tab"

# JSON files
result = UniversalDocumentProcessor.process('config.json')
puts result[:structured_data]

# XML files
result = UniversalDocumentProcessor.process('data.xml')
puts result[:structured_data]
```

### Batch Processing

```ruby
files = ['doc1.txt', 'doc2.csv', 'doc3.json']
results = UniversalDocumentProcessor.batch_process(files)

results.each_with_index do |result, i|
  puts "File #{i + 1}: #{result[:metadata][:format]}"
  puts "Content preview: #{result[:text_content]&.slice(0, 100)}..."
end
```

### Understanding Results

All processing methods return a hash with consistent structure:

```ruby
{
  text_content: "Extracted text content",
  metadata: {
    format: "txt",           # File format detected
    file_size: 1024,         # File size in bytes
    encoding: "UTF-8",       # Text encoding
    delimiter: "comma"       # For CSV/TSV files
  },
  tables: [                  # For structured data (CSV, TSV)
    {
      headers: ["Name", "Age"],
      rows: [["John", "25"], ["Jane", "30"]]
    }
  ],
  structured_data: {...}     # For JSON/XML files
}
```

## 🎯 Advanced Features

### File Format Detection

The gem automatically detects file formats based on extension and content:

```ruby
# Supported formats
formats = {
  text: ['.txt', '.md', '.log'],
  csv: ['.csv'],
  tsv: ['.tsv', '.tab'],
  json: ['.json'],
  xml: ['.xml'],
  pdf: ['.pdf'],      # Requires pdf-reader gem
  word: ['.docx']     # Requires docx gem
}
```

### Custom Processing Options

```ruby
# Process with specific options (if needed in future versions)
result = UniversalDocumentProcessor.process(
  'document.csv',
  options: {
    encoding: 'UTF-8',
    delimiter: ','
  }
)
```

### Error Handling

```ruby
begin
  result = UniversalDocumentProcessor.process('document.pdf')
rescue UniversalDocumentProcessor::DependencyMissingError => e
  puts "Missing dependency: #{e.message}"
  puts "Install with: gem install pdf-reader"
rescue UniversalDocumentProcessor::UnsupportedFormatError => e
  puts "Unsupported file format: #{e.message}"
rescue => e
  puts "Processing error: #{e.message}"
end
```

## ⚡ Performance Guidelines

### File Size Recommendations

Based on performance testing:

| File Size | Processing Time | Recommendation |
|-----------|----------------|----------------|
| < 100 KB  | < 50 ms       | ✅ Excellent for real-time |
| 100 KB - 1 MB | 50-300 ms | ✅ Good for interactive use |
| 1 MB - 5 MB | 300ms - 1.5s | ⚠️ Consider async processing |
| > 5 MB    | > 1.5s        | 🔄 Use batch processing |

### Performance by Format

- **Text files**: Fastest processing, linear with file size
- **CSV/TSV**: Good performance, slight overhead for parsing
- **JSON**: Fast for well-structured data
- **XML**: Moderate performance, depends on complexity
- **PDF**: Slower, depends on pdf-reader gem performance
- **Word**: Moderate, depends on docx gem performance

### Optimization Tips

```ruby
# For large files, process individually
large_files.each do |file|
  result = UniversalDocumentProcessor.process(file)
  # Process result immediately
  handle_result(result)
end

# For many small files, use batch processing
small_files_batch = small_files.each_slice(10).to_a
small_files_batch.each do |batch|
  results = UniversalDocumentProcessor.batch_process(batch)
  # Process batch results
end
```

## 💾 Memory Usage

### Expected Memory Patterns

- **Memory usage**: Typically 2-3x the file size
- **Peak memory**: During processing, returns to baseline after
- **Batch processing**: Memory scales with total batch size

### Memory-Efficient Processing

```ruby
# For large files - process one at a time
def process_large_files_efficiently(file_paths)
  results = []
  
  file_paths.each do |path|
    result = UniversalDocumentProcessor.process(path)
    
    # Extract only what you need
    summary = {
      file: path,
      format: result[:metadata][:format],
      size: result[:metadata][:file_size],
      preview: result[:text_content]&.slice(0, 200)
    }
    
    results << summary
    # result goes out of scope, allowing garbage collection
  end
  
  results
end
```

### Batch Processing Guidelines

```ruby
# Recommended batch sizes
batch_sizes = {
  small_files: 20,    # < 100 KB each
  medium_files: 10,   # 100 KB - 1 MB each  
  large_files: 1      # > 1 MB each
}

# Example batch processing
def smart_batch_process(files)
  files.group_by { |f| File.size(f) }.map do |size_group, file_list|
    batch_size = case size_group
                 when 0..100_000 then 20
                 when 100_001..1_000_000 then 10
                 else 1
                 end
    
    file_list.each_slice(batch_size).map do |batch|
      UniversalDocumentProcessor.batch_process(batch)
    end
  end.flatten
end
```

## 🤖 AI Features

### Setup

```ruby
# Install AI dependency
gem install ruby-openai

# Set API key
ENV['OPENAI_API_KEY'] = 'your-api-key-here'

# Or pass directly
agent = UniversalDocumentProcessor.create_ai_agent(api_key: 'your-key')
```

### AI Processing

```ruby
# Check if AI is available
if UniversalDocumentProcessor.ai_available?
  # AI analysis
  analysis = UniversalDocumentProcessor.ai_analyze('document.txt')
  puts analysis[:summary]
  puts analysis[:key_points]
  
  # AI extraction
  extracted = UniversalDocumentProcessor.ai_extract('document.txt', 'email addresses')
  puts extracted[:results]
  
  # AI summarization
  summary = UniversalDocumentProcessor.ai_summarize('long_document.txt')
  puts summary[:summary]
else
  puts "AI features not available. Install ruby-openai and set OPENAI_API_KEY"
end
```

### AI Agent Direct Usage

```ruby
agent = UniversalDocumentProcessor.create_ai_agent

if agent.ai_available?
  # Process and analyze in one step
  result = agent.analyze_document('document.txt')
  
  # Custom AI queries
  insights = agent.query_document('document.txt', 'What are the main themes?')
else
  puts "AI not available: #{agent.ai_available? ? 'Unknown error' : 'Missing API key'}"
end
```

## 🔧 Troubleshooting

### Common Issues

#### 1. Dependency Missing Errors

```ruby
# Error: pdf-reader gem not found
begin
  result = UniversalDocumentProcessor.process('document.pdf')
rescue UniversalDocumentProcessor::DependencyMissingError => e
  puts e.message
  # Install missing dependency: gem install pdf-reader
end
```

#### 2. Unsupported File Format

```ruby
# Error: Unsupported format
begin
  result = UniversalDocumentProcessor.process('document.xyz')
rescue UniversalDocumentProcessor::UnsupportedFormatError => e
  puts "#{e.message}"
  puts "Supported formats: #{UniversalDocumentProcessor.supported_formats}"
end
```

#### 3. Large File Processing

```ruby
# For very large files, consider streaming or chunking
def process_large_file_safely(file_path)
  file_size = File.size(file_path)
  
  if file_size > 10_000_000  # 10 MB
    puts "Warning: Large file detected (#{file_size / 1_000_000} MB)"
    puts "Processing may take time and use significant memory"
  end
  
  UniversalDocumentProcessor.process(file_path)
end
```

#### 4. Encoding Issues

```ruby
# Handle encoding problems
begin
  result = UniversalDocumentProcessor.process('document.txt')
rescue Encoding::InvalidByteSequenceError => e
  puts "Encoding issue: #{e.message}"
  # Try different encoding or clean the file
end
```

#### 5. AI Features Not Working

```ruby
# Debug AI availability
puts "AI Available: #{UniversalDocumentProcessor.ai_available?}"
puts "Missing Dependencies: #{UniversalDocumentProcessor.missing_dependencies}"

# Check API key
if ENV['OPENAI_API_KEY'].nil? || ENV['OPENAI_API_KEY'].empty?
  puts "OPENAI_API_KEY not set"
else
  puts "API key is set (length: #{ENV['OPENAI_API_KEY'].length})"
end
```

## 🏆 Best Practices

### 1. Error Handling

```ruby
def robust_document_processing(file_path)
  begin
    # Check if file exists
    unless File.exist?(file_path)
      return { error: "File not found: #{file_path}" }
    end
    
    # Check file size
    file_size = File.size(file_path)
    if file_size > 50_000_000  # 50 MB
      return { error: "File too large: #{file_size / 1_000_000} MB" }
    end
    
    # Process the file
    result = UniversalDocumentProcessor.process(file_path)
    
    # Validate result
    if result[:text_content].nil? || result[:text_content].empty?
      return { warning: "No text content extracted", result: result }
    end
    
    { success: true, result: result }
    
  rescue UniversalDocumentProcessor::DependencyMissingError => e
    { error: "Missing dependency", details: e.message }
  rescue UniversalDocumentProcessor::UnsupportedFormatError => e
    { error: "Unsupported format", details: e.message }
  rescue => e
    { error: "Processing failed", details: e.message }
  end
end
```

### 2. Performance Monitoring

```ruby
require 'benchmark'

def process_with_monitoring(file_path)
  start_time = Time.now
  
  result = Benchmark.measure do
    UniversalDocumentProcessor.process(file_path)
  end
  
  end_time = Time.now
  
  puts "Processing time: #{(end_time - start_time).round(3)}s"
  puts "CPU time: #{result.total.round(3)}s"
  
  result
end
```

### 3. Logging

```ruby
require 'logger'

logger = Logger.new(STDOUT)

def process_with_logging(file_path)
  logger.info "Starting processing: #{file_path}"
  
  begin
    result = UniversalDocumentProcessor.process(file_path)
    logger.info "Successfully processed: #{result[:metadata][:format]} format"
    result
  rescue => e
    logger.error "Failed to process #{file_path}: #{e.message}"
    raise
  end
end
```

### 4. Configuration Management

```ruby
class DocumentProcessor
  def initialize(config = {})
    @config = {
      max_file_size: 10_000_000,    # 10 MB
      batch_size: 10,
      enable_ai: ENV['OPENAI_API_KEY'] != nil,
      log_level: :info
    }.merge(config)
  end
  
  def process(file_path)
    validate_file(file_path)
    
    if @config[:enable_ai] && UniversalDocumentProcessor.ai_available?
      UniversalDocumentProcessor.ai_analyze(file_path)
    else
      UniversalDocumentProcessor.process(file_path)
    end
  end
  
  private
  
  def validate_file(file_path)
    raise "File not found" unless File.exist?(file_path)
    raise "File too large" if File.size(file_path) > @config[:max_file_size]
  end
end
```

## ❓ FAQ

### Q: What file formats are supported?

**A:** Core formats (always available):
- Text files: `.txt`, `.md`, `.log`
- CSV files: `.csv`
- TSV files: `.tsv`, `.tab`
- JSON files: `.json`
- XML files: `.xml`

Optional formats (require additional gems):
- PDF files: `.pdf` (requires `pdf-reader`)
- Word documents: `.docx` (requires `docx`)

### Q: How do I enable AI features?

**A:** 
1. Install the ruby-openai gem: `gem install ruby-openai`
2. Set your OpenAI API key: `ENV['OPENAI_API_KEY'] = 'your-key'`
3. Check availability: `UniversalDocumentProcessor.ai_available?`

### Q: What's the maximum file size I can process?

**A:** There's no hard limit, but consider:
- Files < 1 MB: Fast processing
- Files 1-5 MB: Good performance  
- Files > 5 MB: Consider chunking or async processing
- Files > 50 MB: May cause memory issues

### Q: Can I process files in parallel?

**A:** Yes, use Ruby's threading or the batch processing feature:

```ruby
# Batch processing (recommended)
results = UniversalDocumentProcessor.batch_process(files)

# Manual threading
threads = files.map do |file|
  Thread.new { UniversalDocumentProcessor.process(file) }
end
results = threads.map(&:value)
```

### Q: How do I handle Unicode/international characters?

**A:** The gem handles Unicode automatically. Files are processed with UTF-8 encoding by default.

### Q: Can I extend the gem with custom processors?

**A:** Currently, the gem doesn't support custom processors, but you can:
1. Process files with the gem
2. Apply custom logic to the results
3. Submit feature requests for new formats

### Q: How do I report bugs or request features?

**A:** Please visit the project repository and:
1. Check existing issues
2. Create a new issue with details
3. Include sample files (if possible)
4. Specify your Ruby version and OS

### Q: Is this gem thread-safe?

**A:** Yes, the gem is designed to be thread-safe for concurrent processing of different files.

---

## 📞 Support

For additional help:
- Check the [README](README.md) for quick reference
- Review the [CHANGELOG](CHANGELOG.md) for recent updates
- Submit issues on the project repository
- Check `UniversalDocumentProcessor.installation_instructions` for dependency help

Happy document processing! 🚀 