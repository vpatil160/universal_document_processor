module UniversalDocumentProcessor
  class Document
    attr_reader :file_path, :content_type, :file_size, :options, :filename_validation

    class LargeFileError < StandardError; end
    class FileValidationError < StandardError; end
    MAX_FILE_SIZE = 50 * 1024 * 1024 # 50 MB

    def initialize(file_path_or_io, options = {})
      @file_path = file_path_or_io.is_a?(String) ? normalize_file_path(file_path_or_io) : save_temp_file(file_path_or_io)
      @options = options
      # 1. Check file existence and readability
      unless File.exist?(@file_path) && File.readable?(@file_path)
        raise FileValidationError, "File is missing or unreadable: #{@file_path}"
      end
      @content_type = detect_content_type
      @file_size = File.size(@file_path)
      # 2. Large file safeguard
      if @file_size > MAX_FILE_SIZE
        raise LargeFileError, "File size #{@file_size} exceeds maximum allowed (#{MAX_FILE_SIZE} bytes)"
      end
      @filename_validation = validate_filename_encoding
      # 3. Encoding validation and cleaning for text files
      if @content_type =~ /text|plain/
        validation = UniversalDocumentProcessor.validate_file(@file_path)
        unless validation[:valid]
          @cleaned_text_content = UniversalDocumentProcessor.clean_text(validation[:content], {
            remove_null_bytes: true,
            remove_control_chars: true,
            normalize_whitespace: true
          })
        else
          @cleaned_text_content = nil
        end
      end
    end

    def process
      begin
        {
          file_path: @file_path,
          content_type: @content_type,
          file_size: @file_size,
          text_content: extract_text,
          metadata: metadata,
          images: extract_images,
          tables: extract_tables,
          filename_info: filename_info,
          processed_at: Time.current
        }
      rescue LargeFileError, FileValidationError => e
        { error: e.class.name, message: e.message, file_path: @file_path }
      rescue => e
        { error: 'ProcessingError', message: e.message, file_path: @file_path }
      end
    end

    def extract_text
      # Use cleaned text if available (from encoding validation)
      return @cleaned_text_content if defined?(@cleaned_text_content) && @cleaned_text_content
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

    def extract_statistics
      processor.respond_to?(:extract_statistics) ? processor.extract_statistics : {}
    rescue => e
      {}
    end

    def validate_data
      processor.respond_to?(:validate_data) ? processor.validate_data : {}
    rescue => e
      {}
    end

    def extract_formulas
      processor.respond_to?(:extract_formulas) ? processor.extract_formulas : []
    rescue => e
      []
    end

    def to_json
      processor.respond_to?(:to_json) ? processor.to_json : process.to_json
    rescue => e
      process.to_json
    end

    def to_csv(sheet_name = nil)
      processor.respond_to?(:to_csv) ? processor.to_csv(sheet_name) : ""
    rescue => e
      ""
    end

    def to_tsv(sheet_name = nil)
      processor.respond_to?(:to_tsv) ? processor.to_tsv(sheet_name) : ""
    rescue => e
      ""
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
      %w[pdf docx doc xlsx xls pptx ppt txt rtf html xml csv tsv jpg jpeg png gif bmp tiff zip rar 7z]
    end

    def supported?
      supported_formats.include?(file_extension.downcase)
    end

    def japanese_filename?
      Utils::JapaneseFilenameHandler.contains_japanese?(File.basename(@file_path))
    end

    def filename_info
      {
        original_filename: File.basename(@file_path),
        contains_japanese: japanese_filename?,
        validation: @filename_validation,
        japanese_parts: Utils::JapaneseFilenameHandler.extract_japanese_parts(File.basename(@file_path))
      }
    end

    # AI-powered analysis methods
    def ai_analyze(query = nil, options = {})
      ai_agent = create_ai_agent(options)
      ai_agent.analyze_document(process, query)
    end

    def ai_summarize(length: :medium, options: {})
      ai_agent = create_ai_agent(options)
      ai_agent.summarize_document(process, length: length)
    end

    def ai_extract_info(categories = nil, options = {})
      ai_agent = create_ai_agent(options)
      ai_agent.extract_key_information(process, categories)
    end

    def ai_translate(target_language, options = {})
      ai_agent = create_ai_agent(options)
      ai_agent.translate_document(process, target_language)
    end

    def ai_classify(options = {})
      ai_agent = create_ai_agent(options)
      ai_agent.classify_document(process)
    end

    def ai_insights(options = {})
      ai_agent = create_ai_agent(options)
      ai_agent.generate_insights(process)
    end

    def ai_action_items(options = {})
      ai_agent = create_ai_agent(options)
      ai_agent.extract_action_items(process)
    end

    def ai_chat(message, options = {})
      ai_agent = create_ai_agent(options)
      ai_agent.chat(message, process)
    end

    def create_ai_agent(options = {})
      AIAgent.new(options.merge(@options))
    end

    private

    def processor
      @processor ||= create_processor
    end

    def create_processor
      case @content_type
      when /pdf/
        Processors::PdfProcessor.new(@file_path, @options)
      when /wordprocessingml/, /msword/
        Processors::WordProcessor.new(@file_path, @options)
      when /spreadsheetml/, /ms-excel/, /csv/, /tab-separated/
        Processors::ExcelProcessor.new(@file_path, @options)
      when /presentationml/, /ms-powerpoint/
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
      # Try to get original filename from IO if available
      original_filename = io.respond_to?(:original_filename) ? io.original_filename : nil
      extension = original_filename ? File.extname(original_filename) : ".#{file_extension}"
      
      # Create safe temporary filename
      if original_filename && Utils::JapaneseFilenameHandler.contains_japanese?(original_filename)
        safe_name = Utils::JapaneseFilenameHandler.create_safe_temp_filename(original_filename, 'temp')
        temp_file = Tempfile.new([File.basename(safe_name, extension), extension])
      else
        temp_file = Tempfile.new(['document', extension])
      end
      
      temp_file.binmode
      temp_file.write(io.read)
      temp_file.close
      temp_file.path
    end

    def fallback_text_extraction
      begin
        if defined?(Yomu)
          Yomu.new(@file_path).text
        else
          "Unable to extract text: Yomu gem not available. Please install 'yomu' gem for universal text extraction: gem install yomu"
        end
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
        modified_at: File.mtime(@file_path),
        japanese_filename: japanese_filename?,
        filename_encoding: @filename_validation
      }
    end

    def normalize_file_path(file_path)
      Utils::JapaneseFilenameHandler.normalize_filename(file_path)
    end

    def validate_filename_encoding
      Utils::JapaneseFilenameHandler.validate_filename(File.basename(@file_path))
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