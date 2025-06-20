module UniversalDocumentProcessor
  class Document
    attr_reader :file_path, :content_type, :file_size, :options

    def initialize(file_path_or_io, options = {})
      @file_path = file_path_or_io.is_a?(String) ? file_path_or_io : save_temp_file(file_path_or_io)
      @options = options
      @content_type = detect_content_type
      @file_size = File.size(@file_path)
    end

    def process
      {
        file_path: @file_path,
        content_type: @content_type,
        file_size: @file_size,
        text_content: extract_text,
        metadata: metadata,
        images: extract_images,
        tables: extract_tables,
        processed_at: Time.current
      }
    end

    def extract_text
      processor.extract_text
    rescue => e
      fallback_text_extraction
    end

    def metadata
      processor.extract_metadata
    rescue => e
      basic_metadata
    end

    def extract_images
      processor.respond_to?(:extract_images) ? processor.extract_images : []
    rescue => e
      []
    end

    def extract_tables
      processor.respond_to?(:extract_tables) ? processor.extract_tables : []
    rescue => e
      []
    end

    def convert_to(target_format)
      case target_format.to_sym
      when :pdf
        convert_to_pdf
      when :text, :txt
        extract_text
      when :html
        convert_to_html
      when :json
        process.to_json
      else
        raise UnsupportedFormatError, "Conversion to #{target_format} not supported"
      end
    end

    def supported_formats
      %w[pdf docx doc xlsx xls pptx ppt txt rtf html xml csv jpg jpeg png gif bmp tiff zip rar 7z]
    end

    def supported?
      supported_formats.include?(file_extension.downcase)
    end

    private

    def processor
      @processor ||= create_processor
    end

    def create_processor
      case @content_type
      when /pdf/
        Processors::PdfProcessor.new(@file_path, @options)
      when /word/, /document/
        Processors::WordProcessor.new(@file_path, @options)
      when /excel/, /spreadsheet/
        Processors::ExcelProcessor.new(@file_path, @options)
      when /powerpoint/, /presentation/
        Processors::PowerpointProcessor.new(@file_path, @options)
      when /image/
        Processors::ImageProcessor.new(@file_path, @options)
      when /zip/, /archive/, /compressed/
        Processors::ArchiveProcessor.new(@file_path, @options)
      when /text/, /plain/
        Processors::TextProcessor.new(@file_path, @options)
      else
        # Fallback to base processor with universal extraction
        Processors::BaseProcessor.new(@file_path, @options)
      end
    end

    def detect_content_type
      Utils::FileDetector.detect(@file_path)
    end

    def file_extension
      File.extname(@file_path).gsub('.', '')
    end

    def save_temp_file(io)
      temp_file = Tempfile.new(['document', ".#{file_extension}"])
      temp_file.binmode
      temp_file.write(io.read)
      temp_file.close
      temp_file.path
    end

    def fallback_text_extraction
      begin
        Yomu.new(@file_path).text
      rescue => e
        "Unable to extract text: #{e.message}"
      end
    end

    def basic_metadata
      {
        filename: File.basename(@file_path),
        file_size: @file_size,
        content_type: @content_type,
        created_at: File.ctime(@file_path),
        modified_at: File.mtime(@file_path)
      }
    end

    def convert_to_pdf
      # Implementation for PDF conversion
      raise NotImplementedError, "PDF conversion not yet implemented"
    end

    def convert_to_html
      # Implementation for HTML conversion
      raise NotImplementedError, "HTML conversion not yet implemented"
    end
  end
end 