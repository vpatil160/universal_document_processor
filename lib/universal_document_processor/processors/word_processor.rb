module UniversalDocumentProcessor
  module Processors
    class WordProcessor < BaseProcessor
      def extract_text
        with_error_handling do
          if @file_path.end_with?('.docx')
            extract_docx_text
          else
            # Fallback for .doc files
            fallback_text_extraction
          end
        end
      end

      def extract_metadata
        with_error_handling do
          if @file_path.end_with?('.docx')
            extract_docx_metadata
          else
            super
          end
        end
      end

      def extract_images
        with_error_handling do
          return [] unless @file_path.end_with?('.docx')
          
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
        super + [:extract_images, :extract_tables, :extract_styles, :extract_comments]
      end

      private

      def extract_docx_text
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

      def fallback_text_extraction
        # Use Yomu for .doc files or as fallback
        Yomu.new(@file_path).text
      rescue => e
        "Unable to extract text from Word document: #{e.message}"
      end
    end
  end
end 