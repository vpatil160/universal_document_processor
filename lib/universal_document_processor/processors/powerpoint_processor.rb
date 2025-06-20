module UniversalDocumentProcessor
  module Processors
    class PowerpointProcessor < BaseProcessor
      def extract_text
        with_error_handling do
          if @file_path.end_with?('.pptx')
            extract_pptx_text
          else
            # Fallback for .ppt files using Yomu
            fallback_text_extraction
          end
        end
      end

      def extract_metadata
        with_error_handling do
          if @file_path.end_with?('.pptx')
            extract_pptx_metadata
          else
            super
          end
        end
      end

      def extract_slides
        with_error_handling do
          return [] unless @file_path.end_with?('.pptx')
          
          slides = []
          
          # Use zip to read PPTX structure
          Zip::File.open(@file_path) do |zip|
            slide_files = zip.entries.select { |entry| entry.name.match?(/ppt\/slides\/slide\d+\.xml/) }
            
            slide_files.sort_by { |f| f.name[/slide(\d+)/, 1].to_i }.each_with_index do |slide_file, index|
              slide_content = zip.read(slide_file.name)
              slide_xml = Nokogiri::XML(slide_content)
              
              # Extract text from slide
              text_elements = slide_xml.xpath('//a:t', 'a' => 'http://schemas.openxmlformats.org/drawingml/2006/main')
              slide_text = text_elements.map(&:text).join(' ')
              
              slides << {
                slide_number: index + 1,
                text: slide_text,
                has_images: slide_xml.xpath('//a:blip').any?,
                has_charts: slide_xml.xpath('//c:chart').any?,
                has_tables: slide_xml.xpath('//a:tbl').any?
              }
            end
          end
          
          slides
        rescue => e
          # If ZIP parsing fails, return empty array
          []
        end
      end

      def extract_images
        with_error_handling do
          return [] unless @file_path.end_with?('.pptx')
          
          images = []
          
          Zip::File.open(@file_path) do |zip|
            # Find slide files
            slide_files = zip.entries.select { |entry| entry.name.match?(/ppt\/slides\/slide\d+\.xml/) }
            
            slide_files.each_with_index do |slide_file, slide_index|
              slide_content = zip.read(slide_file.name)
              slide_xml = Nokogiri::XML(slide_content)
              
              # Extract image references
              slide_xml.xpath('//a:blip', 'a' => 'http://schemas.openxmlformats.org/drawingml/2006/main').each_with_index do |blip, img_index|
                embed_id = blip['r:embed']
                if embed_id
                  images << {
                    slide_number: slide_index + 1,
                    image_index: img_index + 1,
                    embed_id: embed_id,
                    type: 'embedded'
                  }
                end
              end
            end
          end
          
          images
        rescue => e
          []
        end
      end

      def extract_notes
        with_error_handling do
          return [] unless @file_path.end_with?('.pptx')
          
          notes = []
          
          Zip::File.open(@file_path) do |zip|
            notes_files = zip.entries.select { |entry| entry.name.match?(/ppt\/notesSlides\/notesSlide\d+\.xml/) }
            
            notes_files.sort_by { |f| f.name[/notesSlide(\d+)/, 1].to_i }.each_with_index do |notes_file, index|
              notes_content = zip.read(notes_file.name)
              notes_xml = Nokogiri::XML(notes_content)
              
              # Extract text from notes
              text_elements = notes_xml.xpath('//a:t', 'a' => 'http://schemas.openxmlformats.org/drawingml/2006/main')
              notes_text = text_elements.map(&:text).join(' ')
              
              unless notes_text.strip.empty?
                notes << {
                  slide_number: index + 1,
                  notes: notes_text
                }
              end
            end
          end
          
          notes
        rescue => e
          []
        end
      end

      def supported_operations
        super + [:extract_slides, :extract_images, :extract_notes]
      end

      private

      def extract_pptx_text
        text_content = []
        
        begin
          Zip::File.open(@file_path) do |zip|
            slide_files = zip.entries.select { |entry| entry.name.match?(/ppt\/slides\/slide\d+\.xml/) }
            
            slide_files.sort_by { |f| f.name[/slide(\d+)/, 1].to_i }.each_with_index do |slide_file, index|
              slide_content = zip.read(slide_file.name)
              slide_xml = Nokogiri::XML(slide_content)
              
              text_content << "=== Slide #{index + 1} ==="
              
              # Extract all text elements
              text_elements = slide_xml.xpath('//a:t', 'a' => 'http://schemas.openxmlformats.org/drawingml/2006/main')
              slide_text = text_elements.map(&:text).reject(&:empty?).join(' ')
              
              text_content << slide_text unless slide_text.strip.empty?
              text_content << "" # Add blank line between slides
            end
          end
          
          text_content.join("\n")
        rescue => e
          # Fallback to Yomu if ZIP parsing fails
          fallback_text_extraction
        end
      end

      def extract_pptx_metadata
        slide_count = 0
        has_notes = false
        
        begin
          Zip::File.open(@file_path) do |zip|
            # Count slides
            slide_files = zip.entries.select { |entry| entry.name.match?(/ppt\/slides\/slide\d+\.xml/) }
            slide_count = slide_files.length
            
            # Check for notes
            notes_files = zip.entries.select { |entry| entry.name.match?(/ppt\/notesSlides\/notesSlide\d+\.xml/) }
            has_notes = notes_files.any?
            
            # Try to get core properties
            core_props = nil
            if zip.find_entry('docProps/core.xml')
              core_content = zip.read('docProps/core.xml')
              core_xml = Nokogiri::XML(core_content)
              
              core_props = {
                title: core_xml.xpath('//dc:title').text,
                author: core_xml.xpath('//dc:creator').text,
                subject: core_xml.xpath('//dc:subject').text,
                description: core_xml.xpath('//dc:description').text,
                created_at: core_xml.xpath('//dcterms:created').text,
                modified_at: core_xml.xpath('//dcterms:modified').text
              }
            end
          end
          
          metadata = super.merge({
            slide_count: slide_count,
            has_notes: has_notes,
            presentation_type: 'PowerPoint'
          })
          
          metadata.merge!(core_props) if core_props
          metadata
        rescue => e
          super
        end
      end

      def fallback_text_extraction
        # Use Yomu for .ppt files or as fallback
        Yomu.new(@file_path).text
      rescue => e
        "Unable to extract text from PowerPoint presentation: #{e.message}"
      end
    end
  end
end 