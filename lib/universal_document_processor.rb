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
require_relative 'universal_document_processor/utils/file_detector'

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

  # Get list of available features based on installed dependencies
  def self.available_features
    features = [:text_processing, :html_processing, :xml_processing, :csv_processing, :json_processing, :archive_processing]
    
    features << :pdf_processing if dependency_available?(:pdf_reader)
    features << :word_processing if dependency_available?(:docx)
    features << :excel_processing if dependency_available?(:roo)
    features << :image_processing if dependency_available?(:mini_magick)
    features << :universal_text_extraction if dependency_available?(:yomu)
    features << :pdf_generation if dependency_available?(:prawn)
    
    features
  end
end 