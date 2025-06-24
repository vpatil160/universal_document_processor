# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.2.0] - 2024-01-15
### Added
- **TSV (Tab-Separated Values) File Support**: Complete built-in TSV processing capabilities
  - Native TSV parsing using Ruby CSV library with tab delimiter
  - Text extraction with proper formatting
  - Comprehensive metadata detection (format, delimiter, encoding)
  - Table structure analysis and header detection
  - Statistical analysis and data validation
  - Format conversions: TSV ↔ CSV, TSV → JSON
  - Cross-format compatibility with existing CSV and Excel features
  - New `to_tsv()` method for converting other formats to TSV
  - Enhanced file detector with TSV MIME type mapping
  - Full integration with existing Document class API

### Enhanced
- **ExcelProcessor**: Extended to handle TSV files alongside CSV and Excel formats
- **File Detection**: Added TSV MIME type support (`text/tab-separated-values`)
- **Document Class**: Added `to_tsv()` method and TSV format support
- **Supported Formats**: Updated to include TSV in format list

## [1.0.1] - 2025-06-23

### Fixed
- Updated GitHub repository URLs in gemspec to correct repository location
- Fixed all metadata URLs to point to https://github.com/vpatil160/universal_document_processor

## [1.0.0] - 2025-06-23

### Added
- Initial release of Universal Document Processor
- Support for multiple document formats (PDF, DOC, DOCX, XLS, XLSX, PPT, PPTX, TXT, HTML, XML, CSV, Images, Archives)
- Unified API for document processing across all formats
- Text extraction from all supported formats
- Metadata extraction (author, creation date, file size, etc.)
- Image extraction from documents
- Table detection and extraction
- Character validation and encoding support
- Multi-language support including Japanese (日本語)
- Invalid character detection and cleaning
- Japanese filename handling with proper encoding
- Archive processing (ZIP, RAR, 7Z)
- Document conversion capabilities
- Batch processing support
- Production-ready error handling and fallbacks

### AI Features Added
- **AI-Powered Document Analysis**: Comprehensive document analysis using OpenAI GPT models
- **Document Summarization**: Generate summaries of different lengths (short, medium, long)
- **Information Extraction**: Extract specific categories of information from documents
- **Document Translation**: Translate document content to any language
- **Document Classification**: Classify document type and purpose automatically
- **Insights Generation**: Generate AI-powered insights and recommendations
- **Action Items Extraction**: Extract actionable items and tasks from documents
- **Document Comparison**: Compare multiple documents intelligently
- **Interactive Chat**: Chat with documents using natural language
- **Conversation Memory**: Maintain conversation history for context
- **Custom AI Configuration**: Configurable AI models, temperature, and settings

### Features
- **Processor Classes**: Specialized processors for each document type
- **Japanese Support**: Full support for Japanese text and filenames
- **Character Validation**: Detect and clean invalid characters
- **File Detection**: Intelligent MIME type detection
- **Extensible Architecture**: Easy to add new processors and formats
- **Comprehensive Error Handling**: Graceful fallbacks and error recovery
- **Memory Efficient**: Optimized for large document processing
- **Thread Safe**: Safe for concurrent processing

### Dependencies
- activesupport (~> 7.0)
- marcel (~> 1.0) - MIME type detection
- nokogiri (~> 1.13) - XML/HTML parsing
- rubyzip (~> 2.3) - Archive processing

### Optional Dependencies
- pdf-reader (~> 2.0) - Enhanced PDF processing
- prawn (~> 2.4) - PDF generation
- docx (~> 0.8) - Word document processing
- roo (~> 2.8) - Excel/Spreadsheet processing
- mini_magick (~> 4.11) - Image processing
- yomu (~> 0.2) - Universal text extraction fallback

[Unreleased]: https://github.com/vikas-vpatil/universal_document_processor/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/vikas-vpatil/universal_document_processor/releases/tag/v1.0.0 