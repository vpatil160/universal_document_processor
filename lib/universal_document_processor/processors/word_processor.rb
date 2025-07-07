module UniversalDocumentProcessor
  module Processors
    class WordProcessor < BaseProcessor
      MAX_FILE_SIZE = 50 * 1024 * 1024 # 50 MB

      def extract_text
        validate_file
        with_error_handling do
          if @file_path.end_with?('.docx')
            # Encoding validation for docx (if possible)
            validation = UniversalDocumentProcessor.validate_file(@file_path)
            unless validation[:valid]
              return UniversalDocumentProcessor.clean_text(validation[:content], {
                remove_null_bytes: true,
                remove_control_chars: true,
                normalize_whitespace: true
              })
            end
            extract_docx_text
          elsif @file_path.end_with?('.doc')
            # Encoding validation for doc (if possible)
            validation = UniversalDocumentProcessor.validate_file(@file_path)
            unless validation[:valid]
              return UniversalDocumentProcessor.clean_text(validation[:content], {
                remove_null_bytes: true,
                remove_control_chars: true,
                normalize_whitespace: true
              })
            end
            # Built-in .doc file processing
            fallback_text_extraction
          else
            # Handle other Word formats
            fallback_text_extraction
          end
        end
      end

      def extract_metadata
        with_error_handling do
          if @file_path.end_with?('.docx')
            extract_docx_metadata
          elsif @file_path.end_with?('.doc')
            extract_doc_metadata
          else
            super
          end
        end
      end

      def extract_images
        with_error_handling do
          return [] unless @file_path.end_with?('.docx')
          ensure_docx_available!
          
          images = []
          doc = Docx::Document.open(@file_path)
          
          # Extract embedded images
          doc.doc_xml.xpath('//w:drawing//a:blip').each_with_index do |blip, index|
            embed_id = blip['r:embed']
            if embed_id
              images << {
                index: index + 1,
                embed_id: embed_id,
                type: 'embedded'
              }
            end
          end
          
          images
        end
      end

      def extract_tables
        with_error_handling do
          return [] unless @file_path.end_with?('.docx')
          ensure_docx_available!
          
          tables = []
          doc = Docx::Document.open(@file_path)
          
          doc.tables.each_with_index do |table, table_index|
            table_data = {
              index: table_index + 1,
              rows: table.rows.length,
              columns: table.column_count,
              content: []
            }
            
            table.rows.each do |row|
              row_data = row.cells.map(&:text)
              table_data[:content] << row_data
            end
            
            tables << table_data
          end
          
          tables
        end
      end

      def supported_operations
        if @file_path.end_with?('.docx')
          super + [:extract_images, :extract_tables, :extract_styles, :extract_comments]
        else
          # .doc files support basic text and metadata extraction
          super + [:extract_basic_formatting]
        end
      end

      private

      def validate_file
        raise ProcessingError, "File not found: #{@file_path}" unless File.exist?(@file_path)
        raise ProcessingError, "File is empty: #{@file_path}" if File.zero?(@file_path)
        # Large file safeguard
        if File.size(@file_path) > MAX_FILE_SIZE
          raise ProcessingError, "File size #{File.size(@file_path)} exceeds maximum allowed (#{MAX_FILE_SIZE} bytes)"
        end
      end

      def ensure_docx_available!
        unless defined?(Docx)
          raise DependencyMissingError, "DOCX processing requires the 'docx' gem. Install it with: gem install docx -v '~> 0.8'"
        end
      end

      def extract_docx_text
        ensure_docx_available!
        
        doc = Docx::Document.open(@file_path)
        text_content = []
        
        # Extract paragraphs
        doc.paragraphs.each do |paragraph|
          text_content << paragraph.text unless paragraph.text.strip.empty?
        end
        
        # Extract table content
        doc.tables.each do |table|
          table.rows.each do |row|
            row_text = row.cells.map(&:text).join(' | ')
            text_content << row_text unless row_text.strip.empty?
          end
        end
        
        text_content.join("\n")
      end

      def extract_docx_metadata
        ensure_docx_available!
        
        doc = Docx::Document.open(@file_path)
        core_properties = doc.core_properties
        
        super.merge({
          title: core_properties.title,
          author: core_properties.creator,
          subject: core_properties.subject,
          description: core_properties.description,
          keywords: core_properties.keywords,
          created_at: core_properties.created,
          modified_at: core_properties.modified,
          last_modified_by: core_properties.last_modified_by,
          revision: core_properties.revision,
          word_count: count_words(extract_docx_text),
          paragraph_count: doc.paragraphs.length,
          table_count: doc.tables.length
        })
      rescue => e
        super
      end

      def count_words(text)
        text.split(/\s+/).length
      rescue
        0
      end

      def extract_doc_metadata
        # Extract basic metadata from .doc files
        file_stats = File.stat(@file_path)
        extracted_text = extract_doc_text_builtin
        
        super.merge({
          format: 'Microsoft Word Document (.doc)',
          word_count: count_words(extracted_text),
          character_count: extracted_text.length,
          created_at: file_stats.ctime,
          modified_at: file_stats.mtime,
          file_size: file_stats.size,
          extraction_method: 'Built-in binary parsing'
        })
      rescue => e
        super.merge({
          format: 'Microsoft Word Document (.doc)',
          extraction_error: e.message
        })
      end

      def fallback_text_extraction
        # Built-in .doc file text extraction
        extract_doc_text_builtin
      rescue => e
        "Unable to extract text from Word document: #{e.message}"
      end

      def extract_doc_text_builtin
        # Read .doc file as binary and extract readable text
        content = File.binread(@file_path)
        
        # .doc files store text in a specific format - extract readable ASCII text
        # This is a simplified extraction that works for basic .doc files
        text_content = []
        
        # Look for text patterns in the binary data
        # .doc files often have text stored with null bytes between characters
        content.force_encoding('ASCII-8BIT').scan(/[\x20-\x7E\x0A\x0D]{4,}/) do |match|
          # Clean up the extracted text
          cleaned_text = match.gsub(/[\x00-\x1F\x7F-\xFF]/n, ' ').strip
          text_content << cleaned_text if cleaned_text.length > 3
        end
        
        # Try alternative extraction method if first method yields little text
        if text_content.join(' ').length < 50
          text_content = extract_doc_alternative_method(content)
        end
        
        result = text_content.join("\n").strip
        result.empty? ? "Text extracted from .doc file (content may be limited due to complex formatting)" : result
      end

      def extract_doc_alternative_method(content)
        # Alternative method: look for Word document text patterns
        text_parts = []
        
        # .doc files often have text in UTF-16 or with specific markers
        # Try to find readable text segments
        content.force_encoding('UTF-16LE').encode('UTF-8', invalid: :replace, undef: :replace).scan(/[[:print:]]{5,}/m) do |match|
          cleaned = match.strip
          text_parts << cleaned if cleaned.length > 4 && !cleaned.match?(/^[\x00-\x1F]*$/)
        end
        
        # If UTF-16 doesn't work, try scanning for ASCII patterns
        if text_parts.empty?
          content.force_encoding('ASCII-8BIT').scan(/[a-zA-Z0-9\s\.\,\!\?\;\:]{10,}/n) do |match|
            cleaned = match.strip
            text_parts << cleaned if cleaned.length > 9
          end
        end
        
        text_parts.uniq
      end
    end
  end
end 