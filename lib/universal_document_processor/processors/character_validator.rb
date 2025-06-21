module UniversalDocumentProcessor
  module Processors
    class CharacterValidator
      # Invalid character patterns
      INVALID_CONTROL_CHARS = /[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/
      REPLACEMENT_CHAR = "\uFFFD" # Unicode replacement character
      NULL_BYTE = "\x00"
      
      def self.analyze_text(text)
        return {} if text.nil? || text.empty?
        
        {
          encoding: text.encoding.name,
          valid_encoding: text.valid_encoding?,
          has_invalid_chars: has_invalid_characters?(text),
          has_control_chars: has_control_characters?(text),
          has_null_bytes: has_null_bytes?(text),
          has_replacement_chars: has_replacement_characters?(text),
          has_non_printable: has_non_printable_characters?(text),
          character_issues: detect_character_issues(text),
          cleaned_text: clean_text(text),
          statistics: character_statistics(text),
          japanese_analysis: validate_japanese_text(text)
        }
      end
      
      def self.has_invalid_characters?(text)
        !text.valid_encoding? || text.include?(REPLACEMENT_CHAR)
      end
      
      def self.has_control_characters?(text)
        text.match?(INVALID_CONTROL_CHARS)
      end
      
      def self.has_null_bytes?(text)
        text.include?(NULL_BYTE)
      end
      
      def self.has_replacement_characters?(text)
        text.include?(REPLACEMENT_CHAR)
      end
      
      def self.has_non_printable_characters?(text)
        # Check for non-printable characters (excluding common whitespace)
        text.match?(/[^\p{Print}\s\t\n\r]/)
      end
      
      def self.detect_character_issues(text)
        issues = []
        
        # Check encoding validity
        unless text.valid_encoding?
          issues << {
            type: 'invalid_encoding',
            message: "Text contains invalid #{text.encoding.name} sequences",
            severity: 'high'
          }
        end
        
        # Check for null bytes
        if has_null_bytes?(text)
          null_positions = find_character_positions(text, NULL_BYTE)
          issues << {
            type: 'null_bytes',
            message: "Text contains #{null_positions.length} null bytes",
            positions: null_positions,
            severity: 'high'
          }
        end
        
        # Check for control characters
        if has_control_characters?(text)
          control_chars = text.scan(INVALID_CONTROL_CHARS).uniq
          issues << {
            type: 'control_characters',
            message: "Text contains control characters: #{control_chars.map { |c| "\\x#{c.ord.to_s(16).upcase}" }.join(', ')}",
            characters: control_chars,
            severity: 'medium'
          }
        end
        
        # Check for replacement characters
        if has_replacement_characters?(text)
          replacement_positions = find_character_positions(text, REPLACEMENT_CHAR)
          issues << {
            type: 'replacement_characters',
            message: "Text contains #{replacement_positions.length} replacement characters (corrupted data)",
            positions: replacement_positions,
            severity: 'medium'
          }
        end
        
        # Check for suspicious character patterns
        suspicious_patterns = detect_suspicious_patterns(text)
        unless suspicious_patterns.empty?
          issues << {
            type: 'suspicious_patterns',
            message: "Text contains suspicious character patterns",
            patterns: suspicious_patterns,
            severity: 'low'
          }
        end
        
        issues
      end
      
      def self.clean_text(text, options = {})
        cleaned = text.dup
        
        # Remove null bytes
        cleaned.gsub!(NULL_BYTE, '') if options[:remove_null_bytes] != false
        
        # Remove or replace control characters
        if options[:remove_control_chars] != false
          cleaned.gsub!(INVALID_CONTROL_CHARS, options[:control_char_replacement] || ' ')
        end
        
        # Handle replacement characters
        if options[:remove_replacement_chars]
          cleaned.gsub!(REPLACEMENT_CHAR, '')
        end
        
        # Normalize whitespace
        if options[:normalize_whitespace] != false
          cleaned.gsub!(/\s+/, ' ')
          cleaned.strip!
        end
        
        # Ensure valid encoding
        if options[:force_encoding] && !cleaned.valid_encoding?
          cleaned = cleaned.encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
        end
        
        cleaned
      end
      
      def self.character_statistics(text)
        {
          total_chars: text.length,
          printable_chars: text.count("\u{20}-\u{7E}\u{A0}-\u{D7FF}\u{F900}-\u{FDCF}\u{FDF0}-\u{FFEF}"),
          control_chars: text.scan(INVALID_CONTROL_CHARS).length,
          whitespace_chars: text.count(" \t\n\r"),
          null_bytes: text.count(NULL_BYTE),
          replacement_chars: text.count(REPLACEMENT_CHAR),
          unicode_chars: text.count("\u{80}-\u{FFFF}"),
          ascii_chars: text.count("\u{00}-\u{7F}"),
          # Japanese character statistics
          japanese_chars: count_japanese_characters(text),
          hiragana_chars: text.count("\u{3040}-\u{309F}"),
          katakana_chars: text.count("\u{30A0}-\u{30FF}"),
          kanji_chars: text.count("\u{4E00}-\u{9FAF}"),
          fullwidth_chars: text.count("\u{FF00}-\u{FFEF}"),
          # Other Asian scripts
          chinese_chars: text.count("\u{4E00}-\u{9FFF}"),
          korean_chars: text.count("\u{AC00}-\u{D7A3}")
        }
      end
      
      def self.validate_file_encoding(file_path)
        encodings_to_try = ['UTF-8', 'ISO-8859-1', 'Windows-1252', 'Shift_JIS', 'EUC-JP', 'ASCII']
        
        encodings_to_try.each do |encoding|
          begin
            content = File.read(file_path, encoding: encoding)
            if content.valid_encoding?
              return {
                detected_encoding: encoding,
                valid: true,
                content: content,
                analysis: analyze_text(content)
              }
            end
          rescue Encoding::InvalidByteSequenceError, Encoding::UndefinedConversionError
            next
          end
        end
        
        # If no encoding works, read as binary and analyze
        {
          detected_encoding: 'BINARY',
          valid: false,
          content: File.read(file_path, encoding: 'BINARY'),
          analysis: { has_invalid_chars: true }
        }
      end
      
      def self.repair_text(text, strategy = :conservative)
        case strategy
        when :conservative
          # Only remove clearly invalid characters
          clean_text(text, remove_null_bytes: true, remove_control_chars: true)
        when :aggressive
          # Remove all non-printable characters
          text.gsub(/[^\p{Print}\s]/, '')
        when :replace
          # Replace invalid characters with safe alternatives
          clean_text(text, 
            remove_null_bytes: true, 
            remove_control_chars: true,
            control_char_replacement: ' ',
            force_encoding: true
          )
        else
          text
        end
      end
      
      # Japanese-specific methods
      def self.detect_japanese_script(text)
        scripts = []
        scripts << 'hiragana' if text.match?(/[\u{3040}-\u{309F}]/)
        scripts << 'katakana' if text.match?(/[\u{30A0}-\u{30FF}]/)
        scripts << 'kanji' if text.match?(/[\u{4E00}-\u{9FAF}]/)
        scripts << 'fullwidth' if text.match?(/[\u{FF00}-\u{FFEF}]/)
        scripts
      end

      def self.is_japanese_text?(text)
        japanese_chars = count_japanese_characters(text)
        total_chars = text.gsub(/\s/, '').length
        return false if total_chars == 0
        
        # If more than 10% of non-space characters are Japanese, consider it Japanese text
        (japanese_chars.to_f / total_chars) > 0.1
      end

      def self.count_japanese_characters(text)
        hiragana = text.count("\u{3040}-\u{309F}")
        katakana = text.count("\u{30A0}-\u{30FF}")
        kanji = text.count("\u{4E00}-\u{9FAF}")
        fullwidth = text.count("\u{FF00}-\u{FFEF}")
        
        hiragana + katakana + kanji + fullwidth
      end

      def self.validate_japanese_text(text)
        return { japanese: false } unless is_japanese_text?(text)
        
        {
          japanese: true,
          scripts: detect_japanese_script(text),
          character_count: count_japanese_characters(text),
          mixed_with_latin: text.match?(/[\p{Latin}]/) && text.match?(/[\u{3040}-\u{30FF}\u{4E00}-\u{9FAF}]/),
          valid_japanese: true # Japanese characters are always valid
        }
      end

      private
      
      def self.find_character_positions(text, char)
        positions = []
        text.chars.each_with_index do |c, index|
          positions << index if c == char
        end
        positions
      end
      
      def self.detect_suspicious_patterns(text)
        patterns = []
        
        # Long sequences of the same character
        if text.match?(/(.)\1{20,}/)
          patterns << 'long_repetition'
        end
        
        # Excessive whitespace
        if text.match?(/\s{50,}/)
          patterns << 'excessive_whitespace'
        end
        
        # Mixed scripts that might indicate corruption (but allow common combinations)
        if text.match?(/[\p{Latin}][\p{Cyrillic}\p{Arabic}\p{Hebrew}]/)
          patterns << 'mixed_scripts'
        end
        
        # Note: Japanese mixed with Latin is common and NOT flagged as suspicious
        # Example: "Hello 世界" or "Company株式会社" are normal
        
        patterns
      end
    end
  end
end 