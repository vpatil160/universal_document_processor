module UniversalDocumentProcessor
  module Utils
    class JapaneseFilenameHandler
      # Japanese filename character ranges
      HIRAGANA_RANGE = /[\u{3040}-\u{309F}]/
      KATAKANA_RANGE = /[\u{30A0}-\u{30FF}]/
      KANJI_RANGE = /[\u{4E00}-\u{9FAF}]/
      FULLWIDTH_RANGE = /[\u{FF00}-\u{FFEF}]/
      
      # Combined Japanese character pattern
      JAPANESE_CHARS = /[\u{3040}-\u{309F}\u{30A0}-\u{30FF}\u{4E00}-\u{9FAF}\u{FF00}-\u{FFEF}]/
      
      # Valid filename characters (including Japanese)
      VALID_FILENAME_CHARS = /\A[\u{3040}-\u{309F}\u{30A0}-\u{30FF}\u{4E00}-\u{9FAF}\u{FF00}-\u{FFEF}\w\s\-_.()@#$%&+=!~]*\z/

      def self.contains_japanese?(filename)
        return false unless filename.is_a?(String)
        
        # Ensure UTF-8 encoding for regex matching
        normalized = filename.encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
        normalized.match?(JAPANESE_CHARS)
      rescue Encoding::InvalidByteSequenceError, Encoding::UndefinedConversionError
        false
      end

      def self.normalize_filename(filename)
        return filename unless filename.is_a?(String)
        
        # Ensure UTF-8 encoding
        normalized = filename.encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
        
        # Handle different encoding scenarios
        if normalized.encoding != Encoding::UTF_8
          normalized = normalized.force_encoding('UTF-8')
        end
        
        normalized
      end

      def self.safe_filename(filename)
        normalized = normalize_filename(filename)
        
        # Replace problematic characters while preserving Japanese
        safe = normalized.gsub(/[<>:"|?*]/, '_')
        
        # Handle Windows reserved names
        safe = safe.gsub(/^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])$/i, '_\1')
        
        # Ensure not too long (Windows has 255 char limit, but we'll be conservative)
        if safe.bytesize > 200
          extension = File.extname(safe)
          basename = File.basename(safe, extension)
          # Truncate basename but keep extension
          while (basename + extension).bytesize > 200 && basename.length > 1
            basename = basename[0...-1]
          end
          safe = basename + extension
        end
        
        safe
      end

      def self.validate_filename(filename)
        issues = []
        
        return { valid: false, issues: ['Filename is nil or empty'] } if filename.nil? || filename.empty?
        
        normalized = normalize_filename(filename)
        
        # Check encoding validity
        unless normalized.valid_encoding?
          issues << 'Filename contains invalid encoding sequences'
        end
        
        # Check for null bytes
        if normalized.include?("\x00")
          issues << 'Filename contains null bytes'
        end
        
        # Check for control characters
        if normalized.match?(/[\x00-\x1F\x7F]/)
          issues << 'Filename contains control characters'
        end
        
        # Check length
        if normalized.bytesize > 255
          issues << 'Filename is too long (over 255 bytes)'
        end
        
        # Check for Windows reserved names
        basename = File.basename(normalized, File.extname(normalized))
        if basename.match?(/^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])$/i)
          issues << 'Filename uses Windows reserved name'
        end
        
        {
          valid: issues.empty?,
          issues: issues,
          contains_japanese: contains_japanese?(normalized),
          normalized_filename: normalized,
          safe_filename: safe_filename(filename)
        }
      end

      def self.extract_japanese_parts(filename)
        return {} unless contains_japanese?(filename)
        
        {
          hiragana: filename.scan(HIRAGANA_RANGE),
          katakana: filename.scan(KATAKANA_RANGE),
          kanji: filename.scan(KANJI_RANGE),
          fullwidth: filename.scan(FULLWIDTH_RANGE),
          japanese_count: filename.scan(JAPANESE_CHARS).length
        }
      end

      def self.create_safe_temp_filename(original_filename, prefix = 'doc')
        validation = validate_filename(original_filename)
        
        if validation[:valid]
          # Use the normalized filename if it's valid
          validation[:normalized_filename]
        else
          # Create a safe temporary filename
          extension = File.extname(original_filename)
          timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
          japanese_parts = extract_japanese_parts(original_filename)
          
          if japanese_parts[:japanese_count] > 0
            # Include some Japanese context if possible
            safe_japanese = japanese_parts[:hiragana].first(3).join + 
                           japanese_parts[:katakana].first(3).join + 
                           japanese_parts[:kanji].first(3).join
            "#{prefix}_#{safe_japanese}_#{timestamp}#{extension}"
          else
            "#{prefix}_#{timestamp}#{extension}"
          end
        end
      end

      def self.analyze_filename_encoding(filename)
        encodings_to_try = ['UTF-8', 'Shift_JIS', 'EUC-JP', 'ISO-8859-1', 'Windows-1252']
        
        results = {}
        
        encodings_to_try.each do |encoding|
          begin
            if filename.encoding.name == encoding
              # Already in this encoding
              results[encoding] = {
                valid: filename.valid_encoding?,
                convertible: true,
                contains_japanese: contains_japanese?(filename.dup.force_encoding('UTF-8'))
              }
            else
              # Try to convert to this encoding
              converted = filename.encode(encoding)
              # For Japanese detection, always use UTF-8 version
              utf8_version = converted.encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
              results[encoding] = {
                valid: converted.valid_encoding?,
                convertible: true,
                contains_japanese: contains_japanese?(utf8_version)
              }
            end
          rescue Encoding::InvalidByteSequenceError, Encoding::UndefinedConversionError
            results[encoding] = {
              valid: false,
              convertible: false,
              contains_japanese: false
            }
          end
        end
        
        {
          original_encoding: filename.encoding.name,
          analysis: results,
          recommended_encoding: find_best_encoding(results)
        }
      end

      private

      def self.find_best_encoding(analysis_results)
        # Prefer UTF-8 if valid
        return 'UTF-8' if analysis_results['UTF-8']&.dig(:valid)
        
        # Then try Japanese encodings if they contain Japanese
        ['Shift_JIS', 'EUC-JP'].each do |encoding|
          result = analysis_results[encoding]
          if result&.dig(:valid) && result&.dig(:contains_japanese)
            return encoding
          end
        end
        
        # Fall back to any valid encoding
        analysis_results.each do |encoding, result|
          return encoding if result&.dig(:valid)
        end
        
        'UTF-8' # Default fallback
      end
    end
  end
end 