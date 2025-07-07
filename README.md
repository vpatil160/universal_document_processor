# Universal Document Processor

[![Gem Version](https://badge.fury.io/rb/universal_document_processor.svg)](https://badge.fury.io/rb/universal_document_processor)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Ruby](https://img.shields.io/badge/ruby-%3E%3D%202.7.0-ruby.svg)](https://www.ruby-lang.org/)

A comprehensive Ruby gem that provides unified document processing capabilities across multiple file formats. Extract text, metadata, images, and tables from PDFs, Word documents, Excel spreadsheets, PowerPoint presentations, images, archives, and more with a single, consistent API.

## 🎯 Features

### **Unified Document Processing**
- **Single API** for all document types
- **Intelligent format detection** and processing
- **Production-ready** error handling and fallbacks
- **Extensible architecture** for future enhancements

### **Supported File Formats**
- **📄 Documents**: PDF, DOC, DOCX, RTF
- **📊 Spreadsheets**: XLS, XLSX, CSV, TSV
- **📺 Presentations**: PPT, PPTX
- **🖼️ Images**: JPG, PNG, GIF, BMP, TIFF
- **📁 Archives**: ZIP, RAR, 7Z
- **📄 Text**: TXT, HTML, XML, JSON, Markdown

### **Advanced Content Extraction**
- **Text Extraction**: Full text content from any supported format
- **Metadata Extraction**: File properties, author, creation date, etc.
- **Image Extraction**: Embedded images from documents
- **Table Detection**: Structured data extraction
- **Character Validation**: Invalid character detection and cleaning
- **Multi-language Support**: Full Unicode support including Japanese (日本語)
- **Archive Creation**: Create ZIP files from individual files or directories

### **Character & Encoding Support**
- **Smart encoding detection** (UTF-8, Shift_JIS, EUC-JP, ISO-8859-1)
- **Invalid character detection** and cleaning
- **Japanese text support** (Hiragana, Katakana, Kanji)
- **Control character handling**
- **Text repair and normalization**

## 🚀 Installation

Add this line to your application's Gemfile:

```ruby
gem 'universal_document_processor'
```

And then execute:
```bash
bundle install
```

Or install it yourself as:
```bash
gem install universal_document_processor
```

### Optional Dependencies

For enhanced functionality, install additional gems:

```ruby
# PDF processing
gem 'pdf-reader', '~> 2.0'
gem 'prawn', '~> 2.4'

# Microsoft Office documents
gem 'docx', '~> 0.8'
gem 'roo', '~> 2.8'

# Image processing
gem 'mini_magick', '~> 4.11'

# Universal text extraction fallback
gem 'yomu', '~> 0.2'
```

## 📖 Quick Start

### Basic Usage

```ruby
require 'universal_document_processor'

# Process any document
result = UniversalDocumentProcessor.process('document.pdf')

# Extract text only
text = UniversalDocumentProcessor.extract_text('document.docx')

# Get metadata only
metadata = UniversalDocumentProcessor.get_metadata('spreadsheet.xlsx')
```

### Processing Result

```ruby
result = UniversalDocumentProcessor.process('document.pdf')

# Returns comprehensive information:
{
  file_path: "document.pdf",
  content_type: "application/pdf",
  file_size: 1024576,
  text_content: "Extracted text content...",
  metadata: {
    title: "Document Title",
    author: "Author Name",
    page_count: 25
  },
  images: [...],
  tables: [...],
  processed_at: 2025-07-06 10:30:00 UTC
}
```

## 🔧 Advanced Usage

### Character Validation and Cleaning

```ruby
# Analyze text quality and character issues
analysis = UniversalDocumentProcessor.analyze_text_quality(text)

# Returns:
{
  encoding: "UTF-8",
  valid_encoding: true,
  has_invalid_chars: false,
  has_control_chars: true,
  character_issues: [...],
  statistics: {
    total_chars: 1500,
    japanese_chars: 250,
    hiragana_chars: 100,
    katakana_chars: 50,
    kanji_chars: 100
  },
  japanese_analysis: {
    japanese: true,
    scripts: ['hiragana', 'katakana', 'kanji'],
    mixed_with_latin: true
  }
}
```

### Text Cleaning

```ruby
# Clean text by removing invalid characters
clean_text = UniversalDocumentProcessor.clean_text(corrupted_text, {
  remove_null_bytes: true,
  remove_control_chars: true,
  normalize_whitespace: true
})
```

### File Encoding Validation

```ruby
# Validate file encoding (supports Japanese encodings)
validation = UniversalDocumentProcessor.validate_file('japanese_document.txt')

# Returns:
{
  detected_encoding: "Shift_JIS",
  valid: true,
  content: "こんにちは",
  analysis: {...}
}
```

### Japanese Text Support

```ruby
# Check if text contains Japanese
is_japanese = UniversalDocumentProcessor.japanese_text?("こんにちは World")
# => true

# Detailed Japanese analysis
japanese_info = UniversalDocumentProcessor.validate_japanese_text("こんにちは 世界")
# Returns detailed Japanese character analysis
```

### Batch Processing

```ruby
# Process multiple documents
file_paths = ['file1.pdf', 'file2.docx', 'file3.xlsx']
results = UniversalDocumentProcessor.batch_process(file_paths)

# Returns array with success/error status for each file
```

### Document Conversion

```ruby
# Convert to different formats
text_content = UniversalDocumentProcessor.convert('document.pdf', :text)
json_data = UniversalDocumentProcessor.convert('document.docx', :json)
```

## 📋 Detailed Examples

### Processing PDF Documents

```ruby
# Extract comprehensive PDF information
result = UniversalDocumentProcessor.process('report.pdf')

# Access specific data
puts "Title: #{result[:metadata][:title]}"
puts "Pages: #{result[:metadata][:page_count]}"
puts "Images found: #{result[:images].length}"
puts "Tables found: #{result[:tables].length}"

# Get text content
full_text = result[:text_content]
```

### Processing Excel Spreadsheets

```ruby
# Extract data from Excel files
result = UniversalDocumentProcessor.process('data.xlsx')

# Access spreadsheet-specific metadata
metadata = result[:metadata]
puts "Worksheets: #{metadata[:worksheet_count]}"
puts "Has formulas: #{metadata[:has_formulas]}"

# Extract tables/data
tables = result[:tables]
tables.each_with_index do |table, index|
  puts "Table #{index + 1}: #{table[:rows]} rows"
end
```

### Processing TSV (Tab-Separated Values) Files

```ruby
# Process TSV files with built-in support
result = UniversalDocumentProcessor.process('data.tsv')

# TSV-specific metadata
metadata = result[:metadata]
puts "Format: #{metadata[:format]}"        # => "tsv"
puts "Delimiter: #{metadata[:delimiter]}"  # => "tab"
puts "Rows: #{metadata[:total_rows]}"
puts "Columns: #{metadata[:total_columns]}"
puts "Has headers: #{metadata[:has_headers]}"

# Extract structured data
tables = result[:tables]
table = tables.first
puts "Headers: #{table[:headers].join(', ')}"
puts "Sample row: #{table[:data][1].join(' | ')}"

# Format conversions
document = UniversalDocumentProcessor::Document.new('data.tsv')

# Convert TSV to CSV
csv_output = document.to_csv
puts "CSV conversion: #{csv_output.length} characters"

# Convert TSV to JSON
json_output = document.to_json
puts "JSON conversion: #{json_output.length} characters"

# Convert CSV to TSV
csv_document = UniversalDocumentProcessor::Document.new('data.csv')
tsv_output = csv_document.to_tsv
puts "TSV conversion: #{tsv_output.length} characters"

# Statistical analysis
stats = document.extract_statistics
sheet_stats = stats['Sheet1']
puts "Total cells: #{sheet_stats[:total_cells]}"
puts "Numeric cells: #{sheet_stats[:numeric_cells]}"
puts "Text cells: #{sheet_stats[:text_cells]}"
puts "Average value: #{sheet_stats[:average_value]}"

# Data validation
validation = document.validate_data
sheet_validation = validation['Sheet1']
puts "Data quality score: #{sheet_validation[:data_quality_score]}%"
puts "Empty rows: #{sheet_validation[:empty_rows]}"
puts "Duplicate rows: #{sheet_validation[:duplicate_rows]}"
```

### Processing Word Documents

```ruby
# Extract from Word documents
result = UniversalDocumentProcessor.process('report.docx')

# Get document structure
metadata = result[:metadata]
puts "Word count: #{metadata[:word_count]}"
puts "Paragraph count: #{metadata[:paragraph_count]}"

# Extract embedded images
images = result[:images]
puts "Found #{images.length} embedded images"
```

### Processing Japanese Documents & Filenames

```ruby
# Process Japanese content
japanese_doc = "こんにちは 世界！ Hello World!"
analysis = UniversalDocumentProcessor.analyze_text_quality(japanese_doc)

# Japanese-specific information
japanese_info = analysis[:japanese_analysis]
puts "Contains Japanese: #{japanese_info[:japanese]}"
puts "Scripts found: #{japanese_info[:scripts].join(', ')}"
puts "Mixed with Latin: #{japanese_info[:mixed_with_latin]}"

# Character statistics
stats = analysis[:statistics]
puts "Hiragana: #{stats[:hiragana_chars]}"
puts "Katakana: #{stats[:katakana_chars]}"
puts "Kanji: #{stats[:kanji_chars]}"

# Japanese filename support
filename = "重要な資料_2024年度.pdf"
validation = UniversalDocumentProcessor.validate_filename(filename)
puts "Japanese filename: #{validation[:contains_japanese]}"
puts "Filename valid: #{validation[:valid]}"

# Safe filename generation
safe_name = UniversalDocumentProcessor.safe_filename("データファイル<重要>.xlsx")
puts "Safe filename: #{safe_name}"  # => "データファイル_重要_.xlsx"

# Process documents with Japanese filenames
result = UniversalDocumentProcessor.process("日本語ファイル.pdf")
puts "Original filename: #{result[:filename_info][:original_filename]}"
puts "Contains Japanese: #{result[:filename_info][:contains_japanese]}"
puts "Japanese parts: #{result[:filename_info][:japanese_parts]}"
```

## 🤖 AI Agent Integration

The gem includes a powerful AI agent that provides intelligent document analysis and interaction capabilities using OpenAI's GPT models:

### Quick AI Analysis

```ruby
# Set your OpenAI API key
ENV['OPENAI_API_KEY'] = 'your-api-key-here'

# Quick AI-powered analysis
summary = UniversalDocumentProcessor.ai_summarize('document.pdf', length: :short)
insights = UniversalDocumentProcessor.ai_insights('document.pdf')
classification = UniversalDocumentProcessor.ai_classify('document.pdf')

# Extract specific information
key_info = UniversalDocumentProcessor.ai_extract_info('document.pdf', ['dates', 'names', 'amounts'])
action_items = UniversalDocumentProcessor.ai_action_items('document.pdf')

# Translate documents (great for Japanese documents)
translation = UniversalDocumentProcessor.ai_translate('日本語文書.pdf', 'English')
```

### Interactive AI Agent

```ruby
# Create a persistent AI agent for conversations
agent = UniversalDocumentProcessor.create_ai_agent(
  model: 'gpt-4',
  temperature: 0.7,
  max_history: 10
)

# Process document and start conversation
document = UniversalDocumentProcessor::Document.new('report.pdf')

# Ask questions about the document
response1 = document.ai_chat('What is this document about?')
response2 = document.ai_chat('What are the key financial figures?')
response3 = document.ai_chat('Based on our discussion, what should I focus on?')

# Get conversation summary
summary = agent.conversation_summary
```

### Advanced AI Features

```ruby
# Compare multiple documents
comparison = UniversalDocumentProcessor.ai_compare(
  ['doc1.pdf', 'doc2.pdf', 'doc3.pdf'], 
  :content  # or :themes, :structure, etc.
)

# Document-specific AI analysis
document = UniversalDocumentProcessor::Document.new('business_plan.pdf')

analysis = document.ai_analyze('What are the growth projections?')
insights = document.ai_insights
classification = document.ai_classify
action_items = document.ai_action_items

# Japanese document support
japanese_doc = UniversalDocumentProcessor::Document.new('プロジェクト計画書.pdf')
translation = japanese_doc.ai_translate('English')
summary = japanese_doc.ai_summarize(length: :medium)
```

### AI Configuration Options

```ruby
# Custom AI agent configuration
agent = UniversalDocumentProcessor.create_ai_agent(
  api_key: 'your-openai-key',       # OpenAI API key
  model: 'gpt-4',                   # Model to use (gpt-4, gpt-3.5-turbo)
  temperature: 0.3,                 # Response creativity (0.0-1.0)
  max_history: 20,                  # Conversation memory length
  base_url: 'https://api.openai.com/v1'  # Custom API endpoint
)
```

## 📦 Archive Processing (ZIP Creation & Extraction)

The gem provides comprehensive archive processing capabilities, including both extracting from existing archives and creating new ZIP files.

### Extracting from Archives

```ruby
# Extract text and metadata from ZIP archives
result = UniversalDocumentProcessor.process('archive.zip')

# Access archive-specific metadata
metadata = result[:metadata]
puts "Archive type: #{metadata[:archive_type]}"           # => "zip"
puts "Total files: #{metadata[:total_files]}"             # => 15
puts "Uncompressed size: #{metadata[:total_uncompressed_size]} bytes"
puts "Compression ratio: #{metadata[:compression_ratio]}%" # => 75%
puts "Directory structure: #{metadata[:directory_structure]}"

# Check for specific file types
puts "File types: #{metadata[:file_types]}"               # => {"txt"=>5, "pdf"=>3, "jpg"=>7}
puts "Has executables: #{metadata[:has_executable_files]}" # => false
puts "Largest file: #{metadata[:largest_file][:path]} (#{metadata[:largest_file][:size]} bytes)"

# Extract text from text files within the archive
text_content = result[:text_content]
puts "Combined text from archive: #{text_content.length} characters"
```

### Creating ZIP Archives

```ruby
# Create ZIP from individual files
files_to_zip = ['document1.pdf', 'document2.txt', 'image.jpg']
output_zip = 'my_archive.zip'

zip_path = UniversalDocumentProcessor::Processors::ArchiveProcessor.create_zip(
  output_zip, 
  files_to_zip
)
puts "ZIP created: #{zip_path}"

# Create ZIP from entire directory (preserves folder structure)
directory_to_zip = '/path/to/documents'
archive_path = UniversalDocumentProcessor::Processors::ArchiveProcessor.create_zip(
  'directory_backup.zip',
  directory_to_zip
)
puts "Directory archived: #{archive_path}"

# Working with temporary directories
require 'tmpdir'

Dir.mktmpdir do |tmpdir|
  # Create some test files
  File.write(File.join(tmpdir, 'file1.txt'), 'Hello from file 1')
  File.write(File.join(tmpdir, 'file2.txt'), 'Hello from file 2')
  
  # Create subdirectory with files
  subdir = File.join(tmpdir, 'subfolder')
  Dir.mkdir(subdir)
  File.write(File.join(subdir, 'file3.txt'), 'Hello from subfolder')
  
  # Archive the entire directory structure
  zip_file = File.join(tmpdir, 'complete_backup.zip')
  UniversalDocumentProcessor::Processors::ArchiveProcessor.create_zip(zip_file, tmpdir)
  
  puts "Archive size: #{File.size(zip_file)} bytes"
  
  # Verify archive contents by processing it
  archive_result = UniversalDocumentProcessor.process(zip_file)
  puts "Files in archive: #{archive_result[:metadata][:total_files]}"
end

# Error handling for ZIP creation
begin
  UniversalDocumentProcessor::Processors::ArchiveProcessor.create_zip(
    '/invalid/path/archive.zip',
    ['file1.txt', 'file2.txt']
  )
rescue => e
  puts "Error creating ZIP: #{e.message}"
end

# Validate input before creating ZIP
files = ['doc1.pdf', 'doc2.txt']
files.each do |file|
  unless File.exist?(file)
    puts "Warning: #{file} does not exist"
  end
end
```

### Archive Analysis

```ruby
# Analyze archive security and structure
result = UniversalDocumentProcessor.process('suspicious_archive.zip')
metadata = result[:metadata]

# Security analysis
if metadata[:has_executable_files]
  puts "⚠️  Archive contains executable files"
end

# Directory structure analysis
structure = metadata[:directory_structure]
puts "Top-level directories: #{structure.keys.join(', ')}"

# File type distribution
file_types = metadata[:file_types]
puts "Most common file type: #{file_types.max_by{|k,v| v}}"
```

## 🎌 Japanese Filename Support

The gem provides comprehensive support for Japanese filenames across all operating systems:

### Basic Filename Validation

```ruby
# Check if filename contains Japanese characters
UniversalDocumentProcessor.japanese_filename?("日本語ファイル.pdf")
# => true

# Validate Japanese filename
validation = UniversalDocumentProcessor.validate_filename("こんにちは世界.docx")
puts validation[:valid]              # => true
puts validation[:contains_japanese]  # => true
puts validation[:japanese_parts]     # => {hiragana: ["こ","ん","に","ち","は"], katakana: [], kanji: ["世","界"]}

# Handle mixed language filenames
validation = UniversalDocumentProcessor.validate_filename("Project_プロジェクト_2024.xlsx")
puts validation[:contains_japanese]  # => true
```

### Safe Filename Generation

```ruby
# Create cross-platform safe filenames
problematic_name = "データファイル<重要>:管理.xlsx"
safe_name = UniversalDocumentProcessor.safe_filename(problematic_name)
puts safe_name  # => "データファイル_重要__管理.xlsx"

# Handle extremely long Japanese filenames
long_name = "非常に長いファイル名" * 20 + ".pdf"
safe_name = UniversalDocumentProcessor.safe_filename(long_name)
puts safe_name.bytesize <= 200  # => true (safely truncated)
```

### Encoding Analysis & Normalization

```ruby
# Analyze filename encoding
filename = "データファイル.pdf"
analysis = UniversalDocumentProcessor::Utils::JapaneseFilenameHandler.analyze_filename_encoding(filename)
puts "Original encoding: #{analysis[:original_encoding]}"
puts "Recommended encoding: #{analysis[:recommended_encoding]}"

# Normalize filename to UTF-8
normalized = UniversalDocumentProcessor.normalize_filename(filename)
puts normalized.encoding  # => UTF-8
```

### Document Processing with Japanese Filenames

```ruby
# Process documents with Japanese filenames
result = UniversalDocumentProcessor.process("重要な会議資料.pdf")

# Access filename information
filename_info = result[:filename_info]
puts "Original: #{filename_info[:original_filename]}"
puts "Japanese: #{filename_info[:contains_japanese]}"
puts "Validation: #{filename_info[:validation][:valid]}"

# Japanese character breakdown
japanese_parts = filename_info[:japanese_parts]
puts "Hiragana: #{japanese_parts[:hiragana]&.join('')}"
puts "Katakana: #{japanese_parts[:katakana]&.join('')}"
puts "Kanji: #{japanese_parts[:kanji]&.join('')}"
```

### Cross-Platform Compatibility

```ruby
# Test filename compatibility across platforms
test_files = [
  "日本語ファイル.pdf",        # Standard Japanese
  "こんにちはworld.docx",      # Mixed Japanese-English
  "データ_analysis.xlsx",      # Japanese with underscore
  "会議議事録（重要）.txt"       # Japanese with parentheses
]

test_files.each do |filename|
  validation = UniversalDocumentProcessor.validate_filename(filename)
  safe_version = UniversalDocumentProcessor.safe_filename(filename)
  
  puts "#{filename}:"
  puts "  Windows compatible: #{validation[:valid]}"
  puts "  Safe version: #{safe_version}"
  puts "  Byte size: #{safe_version.bytesize} bytes"
end
```

## 🔍 Character Validation Features

### Detecting Invalid Characters

```ruby
text_with_issues = "Hello\x00World\x01こんにちは"
analysis = UniversalDocumentProcessor.analyze_text_quality(text_with_issues)

# Check for specific issues
puts "Has null bytes: #{analysis[:has_null_bytes]}"
puts "Has control chars: #{analysis[:has_control_chars]}"
puts "Valid encoding: #{analysis[:valid_encoding]}"

# Get detailed issue report
issues = analysis[:character_issues]
issues.each do |issue|
  puts "#{issue[:type]}: #{issue[:message]} (#{issue[:severity]})"
end
```

### Text Repair Strategies

```ruby
corrupted_text = "Hello\x00World\x01こんにちは\uFFFD"

# Conservative repair (recommended)
clean = UniversalDocumentProcessor::Processors::CharacterValidator.repair_text(
  corrupted_text, :conservative
)

# Aggressive repair (removes all non-printable)
clean = UniversalDocumentProcessor::Processors::CharacterValidator.repair_text(
  corrupted_text, :aggressive
)

# Replace strategy (replaces with safe alternatives)
clean = UniversalDocumentProcessor::Processors::CharacterValidator.repair_text(
  corrupted_text, :replace
)
```

## 🎛️ Configuration

### Checking Available Features

```ruby
# Check what features are available based on installed gems
features = UniversalDocumentProcessor.available_features
puts "Available features: #{features.join(', ')}"

# Check specific dependencies
puts "PDF processing: #{UniversalDocumentProcessor.dependency_available?(:pdf_reader)}"
puts "Word processing: #{UniversalDocumentProcessor.dependency_available?(:docx)}"
puts "Excel processing: #{UniversalDocumentProcessor.dependency_available?(:roo)}"
```

### Custom Options

```ruby
# Process with custom options
options = {
  extract_images: true,
  extract_tables: true,
  clean_text: true,
  validate_encoding: true
}

result = UniversalDocumentProcessor.process('document.pdf', options)
```

## 🏗️ Architecture

The gem uses a modular processor-based architecture:

- **BaseProcessor**: Common functionality and interface
- **PdfProcessor**: Advanced PDF processing
- **WordProcessor**: Microsoft Word documents
- **ExcelProcessor**: Spreadsheet processing
- **PowerpointProcessor**: Presentation processing
- **ImageProcessor**: Image analysis and OCR
- **ArchiveProcessor**: Compressed file handling
- **TextProcessor**: Plain text and markup files
- **CharacterValidator**: Text quality and encoding validation

## 🌐 Multi-language Support

### Supported Encodings
- **UTF-8** (recommended)
- **Shift_JIS** (Japanese)
- **EUC-JP** (Japanese)
- **ISO-8859-1** (Latin-1)
- **Windows-1252**
- **ASCII**

### Supported Scripts
- **Latin** (English, European languages)
- **Japanese** (Hiragana, Katakana, Kanji)
- **Chinese** (Simplified/Traditional)
- **Korean** (Hangul)
- **Cyrillic** (Russian, etc.)
- **Arabic**
- **Hebrew**

## ⚡ Performance

### Benchmarks (Average)
- **Small PDF (1-10 pages)**: 0.5-2 seconds
- **Large PDF (100+ pages)**: 5-15 seconds
- **Word Document**: 0.3-1 second
- **Excel Spreadsheet**: 0.5-3 seconds
- **PowerPoint**: 1-5 seconds
- **Image with OCR**: 2-10 seconds

### Best Practices
1. Use **batch processing** for multiple files
2. Process files **asynchronously** for better UX
3. Implement **caching** for frequently accessed documents
4. Set **appropriate timeouts** for large files
5. Monitor **memory usage** in production

## 🔒 Security

### File Validation
- MIME type verification prevents file spoofing
- File size limits prevent resource exhaustion
- Content scanning for malicious payloads
- Sandbox processing for untrusted files

### Best Practices
1. Always **validate uploaded files** before processing
2. Set **reasonable limits** on file size and processing time
3. Use **temporary directories** with proper cleanup
4. **Log processing activities** for audit trails
5. Handle **errors gracefully** without exposing system info

## 🧪 Rails Integration

### Controller Example

```ruby
class DocumentsController < ApplicationController
  def create
    uploaded_file = params[:file]
    
    # Process the document
    result = UniversalDocumentProcessor.process(uploaded_file.tempfile.path)
    
    # Store in database
    @document = Document.create!(
      filename: uploaded_file.original_filename,
      content_type: result[:content_type],
      text_content: result[:text_content],
      metadata: result[:metadata]
    )
    
    render json: { success: true, document: @document }
  rescue UniversalDocumentProcessor::Error => e
    render json: { success: false, error: e.message }, status: 422
  end
end
```

### Background Job Example

```ruby
class DocumentProcessorJob < ApplicationJob
  def perform(document_id)
    document = Document.find(document_id)
    
    result = UniversalDocumentProcessor.process(document.file_path)
    
    document.update!(
      text_content: result[:text_content],
      metadata: result[:metadata],
      processed_at: Time.current
    )
  end
end
```

## 🚨 Error Handling

The gem provides comprehensive error handling with custom exceptions:

```ruby
begin
  result = UniversalDocumentProcessor.process('document.pdf')
rescue UniversalDocumentProcessor::UnsupportedFormatError => e
  # Handle unsupported file format
rescue UniversalDocumentProcessor::ProcessingError => e
  # Handle processing failure
rescue UniversalDocumentProcessor::DependencyMissingError => e
  # Handle missing optional dependency
rescue UniversalDocumentProcessor::Error => e
  # Handle general gem errors
end
```

## 🧪 Testing

Run the test suite:

```bash
bundle exec rspec
```

Run with coverage:

```bash
COVERAGE=true bundle exec rspec
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -am 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Create a Pull Request

### Development Setup

```bash
git clone https://github.com/yourusername/universal_document_processor.git
cd universal_document_processor
bundle install
bundle exec rspec
```

## 📝 Changelog

### Version 1.0.0
- Initial release
- Support for PDF, Word, Excel, PowerPoint, images, archives
- Character validation and cleaning
- Japanese text support
- Multi-encoding support
- Batch processing capabilities

## 🆘 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/universal_document_processor/issues)
- **Documentation**: [Wiki](https://github.com/yourusername/universal_document_processor/wiki)
- **Email**: vikas.v.patil1696@gmail.com

## 📄 License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## 👨‍💻 Author

**Vikas Patil**
- Email: vikas.v.patil1696@gmail.com
- GitHub: [@vpatil160](https://github.com/vpatil160)

## 🙏 Acknowledgments

- Built with Ruby and love ❤️
- Thanks to all the amazing open source libraries this gem depends on
- Special thanks to the Ruby community for continuous inspiration

---

**Made with ❤️ for the Ruby community** 