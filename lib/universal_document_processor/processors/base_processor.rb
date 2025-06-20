module UniversalDocumentProcessor
  module Processors
    class BaseProcessor
      attr_reader :file_path, :options

      def initialize(file_path, options = {})
        @file_path = file_path
        @options = options
      end

      def extract_text
        # Fallback to universal text extraction
        Yomu.new(@file_path).text
      rescue => e
        raise ProcessingError, "Failed to extract text: #{e.message}"
      end

      def extract_metadata
        # Basic file metadata
        {
          filename: File.basename(@file_path),
          file_size: File.size(@file_path),
          content_type: Marcel::MimeType.for(Pathname.new(@file_path)),
          created_at: File.ctime(@file_path),
          modified_at: File.mtime(@file_path)
        }
      rescue => e
        raise ProcessingError, "Failed to extract metadata: #{e.message}"
      end

      def extract_images
        []
      end

      def extract_tables
        []
      end

      def supported_operations
        [:extract_text, :extract_metadata]
      end

      protected

      def validate_file
        raise ProcessingError, "File not found: #{@file_path}" unless File.exist?(@file_path)
        raise ProcessingError, "File is empty: #{@file_path}" if File.zero?(@file_path)
      end

      def with_error_handling
        validate_file
        yield
      rescue => e
        raise ProcessingError, "Processing failed: #{e.message}"
      end
    end
  end
end 