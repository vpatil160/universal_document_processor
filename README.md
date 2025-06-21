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
- **📊 Spreadsheets**: XLS, XLSX, CSV
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
  processed_at: 2024-01-15 10:30:00 UTC
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

### Processing Japanese Documents

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