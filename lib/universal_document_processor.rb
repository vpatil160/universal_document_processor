require 'active_support/all'
require 'marcel'
require 'nokogiri'
require 'zip'

# Optional dependencies - only require if available
begin
  require 'pdf-reader'
rescue LoadError
  # PDF processing will use fallback
end

begin
  require 'prawn'
rescue LoadError
  # PDF generation will not be available
end

begin
  require 'docx'
rescue LoadError
  # Word processing will use fallback
end

begin
  require 'roo'
rescue LoadError
  # Excel processing will use fallback
end

begin
  require 'mini_magick'
rescue LoadError
  # Image processing will use fallback
end

begin
  require 'yomu'
rescue LoadError
  # Universal text extraction will use basic fallback
end

require_relative 'universal_document_processor/version'
require_relative 'universal_document_processor/document'
require_relative 'universal_document_processor/processors/base_processor'
require_relative 'universal_document_processor/processors/pdf_processor'
require_relative 'universal_document_processor/processors/word_processor'
require_relative 'universal_document_processor/processors/excel_processor'
require_relative 'universal_document_processor/processors/powerpoint_processor'
require_relative 'universal_document_processor/processors/image_processor'
require_relative 'universal_document_processor/processors/archive_processor'
require_relative 'universal_document_processor/processors/text_processor'
require_relative 'universal_document_processor/processors/character_validator'
require_relative 'universal_document_processor/utils/file_detector'
require_relative 'universal_document_processor/utils/japanese_filename_handler'
require_relative 'universal_document_processor/ai_agent'

module UniversalDocumentProcessor
  class Error < StandardError; end
  class UnsupportedFormatError < Error; end
  class ProcessingError < Error; end
  class DependencyMissingError < Error; end

  # Main entry point for document processing
  def self.process(file_path_or_io, options = {})
    Document.new(file_path_or_io, options).process
  end

  # Extract text from any document
  def self.extract_text(file_path_or_io, options = {})
    Document.new(file_path_or_io, options).extract_text
  end

  # Get document metadata
  def self.get_metadata(file_path_or_io, options = {})
    Document.new(file_path_or_io, options).metadata
  end

  # Analyze text for invalid characters and encoding issues
  def self.analyze_text_quality(text)
    Processors::CharacterValidator.analyze_text(text)
  end

  # Validate file encoding and character issues
  def self.validate_file(file_path)
    Processors::CharacterValidator.validate_file_encoding(file_path)
  end

  # Clean text by removing invalid characters
  def self.clean_text(text, options = {})
    Processors::CharacterValidator.clean_text(text, options)
  end

  # Validate Japanese text specifically
  def self.validate_japanese_text(text)
    Processors::CharacterValidator.validate_japanese_text(text)
  end

  # Check if text contains Japanese characters
  def self.japanese_text?(text)
    Processors::CharacterValidator.is_japanese_text?(text)
  end

  # Japanese filename support methods
  def self.japanese_filename?(filename)
    Utils::JapaneseFilenameHandler.contains_japanese?(filename)
  end

  def self.validate_filename(filename)
    Utils::JapaneseFilenameHandler.validate_filename(filename)
  end

  def self.safe_filename(filename)
    Utils::JapaneseFilenameHandler.safe_filename(filename)
  end

  def self.normalize_filename(filename)
    Utils::JapaneseFilenameHandler.normalize_filename(filename)
  end

  # AI-powered document analysis methods
  def self.ai_analyze(file_path, options = {})
    document_result = process(file_path, options)
    ai_agent = AIAgent.new(options)
    unless ai_agent.ai_available?
      raise DependencyMissingError, "AI features require an OpenAI API key. Set OPENAI_API_KEY environment variable or pass api_key in options."
    end
    ai_agent.analyze_document(document_result, options[:query])
  end

  def self.ai_summarize(file_path, length: :medium, options: {})
    document_result = process(file_path, options)
    ai_agent = AIAgent.new(options)
    unless ai_agent.ai_available?
      raise DependencyMissingError, "AI features require an OpenAI API key. Set OPENAI_API_KEY environment variable or pass api_key in options."
    end
    ai_agent.summarize_document(document_result, length: length)
  end

  def self.ai_extract_info(file_path, categories = nil, options = {})
    document_result = process(file_path, options)
    ai_agent = AIAgent.new(options)
    unless ai_agent.ai_available?
      raise DependencyMissingError, "AI features require an OpenAI API key. Set OPENAI_API_KEY environment variable or pass api_key in options."
    end
    ai_agent.extract_key_information(document_result, categories)
  end

  def self.ai_translate(file_path, target_language, options = {})
    document_result = process(file_path, options)
    ai_agent = AIAgent.new(options)
    unless ai_agent.ai_available?
      raise DependencyMissingError, "AI features require an OpenAI API key. Set OPENAI_API_KEY environment variable or pass api_key in options."
    end
    ai_agent.translate_document(document_result, target_language)
  end

  def self.ai_classify(file_path, options = {})
    document_result = process(file_path, options)
    ai_agent = AIAgent.new(options)
    unless ai_agent.ai_available?
      raise DependencyMissingError, "AI features require an OpenAI API key. Set OPENAI_API_KEY environment variable or pass api_key in options."
    end
    ai_agent.classify_document(document_result)
  end

  def self.ai_insights(file_path, options = {})
    document_result = process(file_path, options)
    ai_agent = AIAgent.new(options)
    unless ai_agent.ai_available?
      raise DependencyMissingError, "AI features require an OpenAI API key. Set OPENAI_API_KEY environment variable or pass api_key in options."
    end
    ai_agent.generate_insights(document_result)
  end

  def self.ai_action_items(file_path, options = {})
    document_result = process(file_path, options)
    ai_agent = AIAgent.new(options)
    unless ai_agent.ai_available?
      raise DependencyMissingError, "AI features require an OpenAI API key. Set OPENAI_API_KEY environment variable or pass api_key in options."
    end
    ai_agent.extract_action_items(document_result)
  end

  def self.ai_compare(file_paths, comparison_type = :content, options = {})
    document_results = file_paths.map { |path| process(path, options) }
    ai_agent = AIAgent.new(options)
    unless ai_agent.ai_available?
      raise DependencyMissingError, "AI features require an OpenAI API key. Set OPENAI_API_KEY environment variable or pass api_key in options."
    end
    ai_agent.compare_documents(document_results, comparison_type)
  end

  def self.create_ai_agent(options = {})
    AIAgent.new(options)
  end

  # Check if AI features are available
  def self.ai_available?(options = {})
    ai_agent = AIAgent.new(options)
    ai_agent.ai_available?
  end

  # Convert document to different format
  def self.convert(file_path_or_io, target_format, options = {})
    Document.new(file_path_or_io, options).convert_to(target_format)
  end

  # Batch process multiple documents
  def self.batch_process(file_paths, options = {})
    file_paths.map do |file_path|
      begin
        process(file_path, options)
      rescue => e
        { file: file_path, error: e.message, success: false }
      end
    end
  end

  # Check if a dependency is available
  def self.dependency_available?(dependency)
    case dependency.to_sym
    when :pdf_reader
      defined?(PDF::Reader)
    when :docx
      defined?(Docx)
    when :roo
      defined?(Roo)
    when :mini_magick
      defined?(MiniMagick)
    when :yomu
      defined?(Yomu)
    when :prawn
      defined?(Prawn)
    else
      false
    end
  end

  # Get list of optional dependencies
  def self.optional_dependencies
    {
      'pdf-reader' => '~> 2.0',      # PDF text extraction
      'prawn' => '~> 2.4',           # PDF generation
      'docx' => '~> 0.8',            # Word document processing
      'roo' => '~> 2.8',             # Excel/Spreadsheet processing
      'mini_magick' => '~> 4.11',    # Image processing
      'yomu' => '~> 0.2'             # Universal text extraction fallback
    }
  end

  # Check which optional dependencies are missing
  def self.missing_dependencies
    missing = []
    missing << 'pdf-reader' unless dependency_available?(:pdf_reader)
    missing << 'prawn' unless dependency_available?(:prawn)
    missing << 'docx' unless dependency_available?(:docx)
    missing << 'roo' unless dependency_available?(:roo)
    missing << 'mini_magick' unless dependency_available?(:mini_magick)
    missing << 'yomu' unless dependency_available?(:yomu)
    missing
  end

  # Generate installation instructions for missing dependencies
  def self.installation_instructions
    missing = missing_dependencies
    return "All optional dependencies are installed!" if missing.empty?

    instructions = ["To enable additional features, install these optional gems:"]
    missing.each do |gem_name|
      version = optional_dependencies[gem_name]
      instructions << "  gem install #{gem_name} -v '#{version}'"
    end
    
    instructions << ""
    instructions << "Or add to your Gemfile:"
    missing.each do |gem_name|
      version = optional_dependencies[gem_name]
      instructions << "  gem '#{gem_name}', '#{version}'"
    end
    
    instructions.join("\n")
  end

  # Get list of available features based on installed dependencies
  def self.available_features
    features = [:text_processing, :html_processing, :xml_processing, :csv_processing, :json_processing, :archive_processing, :tsv_processing]
    
    features << :pdf_processing if dependency_available?(:pdf_reader)
    features << :word_processing if dependency_available?(:docx)
    features << :excel_processing if dependency_available?(:roo)
    features << :image_processing if dependency_available?(:mini_magick)
    features << :universal_text_extraction if dependency_available?(:yomu)
    features << :pdf_generation if dependency_available?(:prawn)
    
    # Check AI availability without creating circular dependency
    begin
      ai_agent = AIAgent.new
      features << :ai_processing if ai_agent.ai_enabled
    rescue
      # AI not available
    end
    
    features
  end
end 