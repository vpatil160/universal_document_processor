module UniversalDocumentProcessor
  module Processors
    class TextProcessor < BaseProcessor
      def extract_text
        with_error_handling do
          case detect_text_format
          when :rtf
            extract_rtf_text
          when :html
            extract_html_text
          when :xml
            extract_xml_text
          when :csv
            extract_csv_text
          when :json
            extract_json_text
          else
            extract_plain_text
          end
        end
      end

      def extract_metadata
        with_error_handling do
          content = File.read(@file_path, encoding: detect_encoding)
          
          super.merge({
            text_format: detect_text_format,
            encoding: detect_encoding,
            line_count: content.lines.count,
            word_count: count_words(content),
            character_count: content.length,
            character_count_no_spaces: content.gsub(/\s/, '').length,
            paragraph_count: count_paragraphs(content),
            language: detect_language(content),
            has_urls: has_urls?(content),
            has_emails: has_emails?(content),
            has_phone_numbers: has_phone_numbers?(content)
          })
        end
      end

      def extract_structure
        with_error_handling do
          case detect_text_format
          when :html
            extract_html_structure
          when :xml
            extract_xml_structure
          when :csv
            extract_csv_structure
          when :json
            extract_json_structure
          else
            extract_plain_structure
          end
        end
      end

      def extract_links
        with_error_handling do
          content = File.read(@file_path, encoding: detect_encoding)
          
          links = {
            urls: extract_urls(content),
            emails: extract_emails(content),
            phone_numbers: extract_phone_numbers(content)
          }
          
          if detect_text_format == :html
            links.merge!(extract_html_links)
          end
          
          links
        end
      end

      def supported_operations
        super + [:extract_structure, :extract_links, :analyze_sentiment, :extract_keywords]
      end

      private

      def detect_text_format
        extension = File.extname(@file_path).downcase
        case extension
        when '.rtf'
          :rtf
        when '.html', '.htm'
          :html
        when '.xml'
          :xml
        when '.csv'
          :csv
        when '.json'
          :json
        when '.md'
          :markdown
        else
          # Try to detect by content
          content = File.read(@file_path, 1000, encoding: 'UTF-8') rescue nil
          return :plain unless content
          
          if content.start_with?('{\rtf')
            :rtf
          elsif content.match?(/<html|<HTML|<!DOCTYPE/i)
            :html
          elsif content.match?(/<?xml|<\w+.*>/i)
            :xml
          elsif content.match?(/^[^,\n]*,[^,\n]*,/)
            :csv
          elsif content.strip.start_with?('{') || content.strip.start_with?('[')
            :json
          else
            :plain
          end
        end
      end

      def detect_encoding
        # Simple encoding detection
        begin
          content = File.read(@file_path, encoding: 'UTF-8')
          'UTF-8'
        rescue Encoding::InvalidByteSequenceError
          begin
            content = File.read(@file_path, encoding: 'ISO-8859-1')
            'ISO-8859-1'
          rescue
            'ASCII'
          end
        end
      end

      def extract_plain_text
        File.read(@file_path, encoding: detect_encoding)
      end

      def extract_rtf_text
        # RTF text extraction would require RTF parsing library
        # This is a simplified version
        content = File.read(@file_path, encoding: detect_encoding)
        # Remove RTF control codes (basic cleanup)
        content.gsub(/\\[a-z]+\d*\s?/i, '').gsub(/[{}]/, '').strip
      rescue => e
        fallback_text_extraction
      end

      def extract_html_text
        content = File.read(@file_path, encoding: detect_encoding)
        doc = Nokogiri::HTML(content)
        
        # Remove script and style elements
        doc.xpath('//script | //style').remove
        
        # Extract text content
        doc.text.gsub(/\s+/, ' ').strip
      rescue => e
        fallback_text_extraction
      end

      def extract_xml_text
        content = File.read(@file_path, encoding: detect_encoding)
        doc = Nokogiri::XML(content)
        doc.text.gsub(/\s+/, ' ').strip
      rescue => e
        fallback_text_extraction
      end

      def extract_csv_text
        content = File.read(@file_path, encoding: detect_encoding)
        # Convert CSV to readable text format
        lines = content.lines
        header = lines.first&.strip
        
        text_content = ["CSV Data:"]
        text_content << "Header: #{header}" if header
        text_content << "Rows: #{lines.length - 1}" if lines.length > 1
        text_content << "\nSample data:"
        text_content << lines[1..5].join if lines.length > 1
        
        text_content.join("\n")
      rescue => e
        fallback_text_extraction
      end

      def extract_json_text
        content = File.read(@file_path, encoding: detect_encoding)
        begin
          json_data = JSON.parse(content)
          "JSON Data: #{json_data.inspect}"
        rescue JSON::ParserError
          content
        end
      rescue => e
        fallback_text_extraction
      end

      def extract_html_structure
        content = File.read(@file_path, encoding: detect_encoding)
        doc = Nokogiri::HTML(content)
        
        {
          title: doc.title,
          headings: extract_headings(doc),
          links: doc.css('a').map { |link| { text: link.text, href: link['href'] } },
          images: doc.css('img').map { |img| { alt: img['alt'], src: img['src'] } },
          forms: doc.css('form').length,
          tables: doc.css('table').length
        }
      rescue => e
        {}
      end

      def extract_xml_structure
        content = File.read(@file_path, encoding: detect_encoding)
        doc = Nokogiri::XML(content)
        
        {
          root_element: doc.root&.name,
          namespaces: doc.namespaces,
          element_count: doc.xpath('//*').length,
          attribute_count: doc.xpath('//@*').length
        }
      rescue => e
        {}
      end

      def extract_csv_structure
        content = File.read(@file_path, encoding: detect_encoding)
        lines = content.lines
        
        {
          rows: lines.length,
          columns: lines.first&.split(',')&.length || 0,
          headers: lines.first&.strip&.split(','),
          sample_data: lines[1..3]&.map { |line| line.strip.split(',') }
        }
      rescue => e
        {}
      end

      def extract_json_structure
        content = File.read(@file_path, encoding: detect_encoding)
        begin
          json_data = JSON.parse(content)
          analyze_json_structure(json_data)
        rescue JSON::ParserError
          { error: 'Invalid JSON format' }
        end
      rescue => e
        {}
      end

      def extract_plain_structure
        content = File.read(@file_path, encoding: detect_encoding)
        
        {
          lines: content.lines.count,
          paragraphs: count_paragraphs(content),
          words: count_words(content),
          characters: content.length
        }
      end

      def count_words(text)
        text.scan(/\b\w+\b/).length
      end

      def count_paragraphs(text)
        text.split(/\n\s*\n/).length
      end

      def detect_language(text)
        # Simple language detection based on common words
        # This is a placeholder - would use a proper language detection library
        sample = text[0..1000].downcase
        
        if sample.match?(/\b(the|and|for|are|but|not|you|all|can|had|her|was|one|our|out|day|get|has|him|his|how|its|may|new|now|old|see|two|who|boy|did|man|men|run|she|too|use|way|who|oil|sit|set|run|hot|let|say|she|try|ask|may|own|say|she|too|use|way|who|oil|sit|set|run|hot|let|say|she|try|ask|may|own)\b/)
          'English'
        else
          'Unknown'
        end
      end

      def has_urls?(text)
        text.match?(/https?:\/\/[^\s]+/)
      end

      def has_emails?(text)
        text.match?(/\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b/)
      end

      def has_phone_numbers?(text)
        text.match?(/\b\d{3}[-.]?\d{3}[-.]?\d{4}\b/)
      end

      def extract_urls(text)
        text.scan(/https?:\/\/[^\s]+/)
      end

      def extract_emails(text)
        text.scan(/\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b/)
      end

      def extract_phone_numbers(text)
        text.scan(/\b\d{3}[-.]?\d{3}[-.]?\d{4}\b/)
      end

      def extract_html_links
        content = File.read(@file_path, encoding: detect_encoding)
        doc = Nokogiri::HTML(content)
        
        {
          internal_links: doc.css('a[href^="/"], a[href^="#"]').map { |link| link['href'] },
          external_links: doc.css('a[href^="http"]').map { |link| link['href'] },
          email_links: doc.css('a[href^="mailto:"]').map { |link| link['href'] }
        }
      rescue
        {}
      end

      def extract_headings(doc)
        headings = {}
        (1..6).each do |level|
          headings["h#{level}"] = doc.css("h#{level}").map(&:text)
        end
        headings
      end

      def analyze_json_structure(data, path = [])
        case data
        when Hash
          {
            type: 'object',
            keys: data.keys,
            nested_structure: data.map { |k, v| [k, analyze_json_structure(v, path + [k])] }.to_h
          }
        when Array
          {
            type: 'array',
            length: data.length,
            element_types: data.map { |item| analyze_json_structure(item, path + ['[]']) }.uniq
          }
        else
          {
            type: data.class.name.downcase,
            value: data.is_a?(String) && data.length > 100 ? "#{data[0..100]}..." : data
          }
        end
      end

      def fallback_text_extraction
        File.read(@file_path, encoding: detect_encoding)
      rescue => e
        "Unable to extract text: #{e.message}"
      end
    end
  end
end 