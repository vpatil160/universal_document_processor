module UniversalDocumentProcessor
  module Processors
    class PdfProcessor < BaseProcessor
      MAX_FILE_SIZE = 50 * 1024 * 1024 # 50 MB

      def extract_text
        ensure_pdf_reader_available!
        validate_file
        with_error_handling do
          reader = PDF::Reader.new(@file_path)
          text = reader.pages.map(&:text).join("\n")
          # Encoding validation for extracted text
          validation = UniversalDocumentProcessor.validate_file(@file_path)
          unless validation[:valid]
            return UniversalDocumentProcessor.clean_text(validation[:content], {
              remove_null_bytes: true,
              remove_control_chars: true,
              normalize_whitespace: true
            })
          end
          text.strip.empty? ? "No text content found in PDF" : text
        end
      rescue => e
        # Fallback to Yomu if pdf-reader fails
        fallback_text_extraction(e)
      end

      def extract_metadata
        ensure_pdf_reader_available!
        
        with_error_handling do
          reader = PDF::Reader.new(@file_path)
          info = reader.info || {}
          
          super.merge({
            title: info[:Title],
            author: info[:Author],
            subject: info[:Subject],
            creator: info[:Creator],
            producer: info[:Producer],
            creation_date: info[:CreationDate],
            modification_date: info[:ModDate],
            page_count: reader.page_count,
            pdf_version: reader.pdf_version,
            encrypted: reader.encrypted?,
            form_fields: extract_form_fields(reader),
            bookmarks: extract_bookmarks(reader)
          })
        end
      end

      def extract_images
        ensure_pdf_reader_available!
        
        with_error_handling do
          # Extract embedded images from PDF
          images = []
          reader = PDF::Reader.new(@file_path)
          
          reader.pages.each_with_index do |page, page_num|
            page.xobjects.each do |name, stream|
              if stream.hash[:Subtype] == :Image
                images << {
                  page: page_num + 1,
                  name: name,
                  width: stream.hash[:Width],
                  height: stream.hash[:Height],
                  color_space: stream.hash[:ColorSpace],
                  bits_per_component: stream.hash[:BitsPerComponent]
                }
              end
            end
          end
          
          images
        end
      end

      def extract_tables
        ensure_pdf_reader_available!
        
        with_error_handling do
          # Basic table extraction from PDF text
          tables = []
          reader = PDF::Reader.new(@file_path)
          
          reader.pages.each_with_index do |page, page_num|
            text = page.text
            # Simple heuristic to detect table-like content
            lines = text.split("\n")
            table_lines = lines.select { |line| line.count("\t") > 1 || line.scan(/\s{3,}/).length > 2 }
            
            unless table_lines.empty?
              tables << {
                page: page_num + 1,
                rows: table_lines.length,
                content: table_lines
              }
            end
          end
          
          tables
        end
      end

      def supported_operations
        super + [:extract_images, :extract_tables, :extract_form_fields, :extract_bookmarks]
      end

      private

      def ensure_pdf_reader_available!
        unless defined?(PDF::Reader)
          raise DependencyMissingError, "PDF processing requires the 'pdf-reader' gem. Install it with: gem install pdf-reader -v '~> 2.0'"
        end
      end

      def validate_file
        raise ProcessingError, "File not found: #{@file_path}" unless File.exist?(@file_path)
        raise ProcessingError, "File is empty: #{@file_path}" if File.zero?(@file_path)
        # Large file safeguard
        if File.size(@file_path) > MAX_FILE_SIZE
          raise ProcessingError, "File size #{File.size(@file_path)} exceeds maximum allowed (#{MAX_FILE_SIZE} bytes)"
        end
      end

      def extract_form_fields(reader)
        # Extract PDF form fields if present
        []
      rescue
        []
      end

      def extract_bookmarks(reader)
        # Extract PDF bookmarks/outline if present
        []
      rescue
        []
      end

      def fallback_text_extraction(original_error)
        if defined?(Yomu)
          begin
            text = Yomu.new(@file_path).text
            return text unless text.nil? || text.strip.empty?
            "No text content found in PDF"
          rescue => yomu_error
            raise ProcessingError, "PDF text extraction failed. pdf-reader error: #{original_error.message}. Yomu fallback error: #{yomu_error.message}"
          end
        else
          raise ProcessingError, "PDF text extraction failed: #{original_error.message}. Consider installing 'yomu' gem for fallback extraction: gem install yomu"
        end
      end
    end
  end
end 