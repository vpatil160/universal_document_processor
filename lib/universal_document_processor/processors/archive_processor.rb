module UniversalDocumentProcessor
  module Processors
    class ArchiveProcessor < BaseProcessor
      def extract_text
        with_error_handling do
          files_list = list_files
          text_content = ["=== Archive Contents ==="]
          
          files_list.each do |file_info|
            text_content << "#{file_info[:path]} (#{file_info[:size]} bytes)"
          end
          
          # Try to extract text from text files within the archive
          text_files = extract_text_files
          unless text_files.empty?
            text_content << "\n=== Text File Contents ==="
            text_files.each do |file_path, content|
              text_content << "\n--- #{file_path} ---"
              text_content << content[0..1000] # Limit to first 1000 chars
              text_content << "..." if content.length > 1000
            end
          end
          
          text_content.join("\n")
        end
      end

      def extract_metadata
        with_error_handling do
          files_list = list_files
          
          super.merge({
            archive_type: detect_archive_type,
            total_files: files_list.length,
            total_uncompressed_size: files_list.sum { |f| f[:size] },
            file_types: analyze_file_types(files_list),
            directory_structure: build_directory_structure(files_list),
            has_executable_files: has_executable_files?(files_list),
            largest_file: find_largest_file(files_list),
            compression_ratio: calculate_compression_ratio
          })
        end
      end

      def list_files
        with_error_handling do
          case detect_archive_type
          when :zip
            list_zip_files
          when :rar
            list_rar_files
          when :seven_zip
            list_7z_files
          else
            []
          end
        end
      end

      def extract_file(file_path, output_path = nil)
        with_error_handling do
          case detect_archive_type
          when :zip
            extract_zip_file(file_path, output_path)
          when :rar
            extract_rar_file(file_path, output_path)
          when :seven_zip
            extract_7z_file(file_path, output_path)
          else
            raise UnsupportedFormatError, "Unsupported archive format"
          end
        end
      end

      def extract_all(output_directory)
        with_error_handling do
          case detect_archive_type
          when :zip
            extract_all_zip(output_directory)
          when :rar
            extract_all_rar(output_directory)
          when :seven_zip
            extract_all_7z(output_directory)
          else
            raise UnsupportedFormatError, "Unsupported archive format"
          end
        end
      end

      def supported_operations
        super + [:list_files, :extract_file, :extract_all, :analyze_security]
      end

      private

      def detect_archive_type
        extension = File.extname(@file_path).downcase
        case extension
        when '.zip'
          :zip
        when '.rar'
          :rar
        when '.7z'
          :seven_zip
        else
          # Try to detect by file signature
          File.open(@file_path, 'rb') do |file|
            signature = file.read(4)
            case signature
            when "PK\x03\x04", "PK\x05\x06", "PK\x07\x08"
              :zip
            when "Rar!"
              :rar
            when "7z\xBC\xAF"
              :seven_zip
            else
              :unknown
            end
          end
        end
      end

      def list_zip_files
        files = []
        Zip::File.open(@file_path) do |zip|
          zip.each do |entry|
            files << {
              path: entry.name,
              size: entry.size,
              compressed_size: entry.compressed_size,
              is_directory: entry.directory?,
              modified_time: entry.time,
              crc: entry.crc
            }
          end
        end
        files
      end

      def list_rar_files
        # RAR support would require external library or system command
        # This is a placeholder implementation
        []
      end

      def list_7z_files
        # 7z support would require external library or system command
        # This is a placeholder implementation
        []
      end

      def extract_zip_file(file_path, output_path)
        Zip::File.open(@file_path) do |zip|
          entry = zip.find_entry(file_path)
          if entry
            if output_path
              entry.extract(output_path)
              output_path
            else
              entry.get_input_stream.read
            end
          else
            raise ProcessingError, "File not found in archive: #{file_path}"
          end
        end
      end

      def extract_rar_file(file_path, output_path)
        # RAR extraction would require external library
        raise NotImplementedError, "RAR extraction not implemented"
      end

      def extract_7z_file(file_path, output_path)
        # 7z extraction would require external library
        raise NotImplementedError, "7z extraction not implemented"
      end

      def extract_all_zip(output_directory)
        FileUtils.mkdir_p(output_directory)
        Zip::File.open(@file_path) do |zip|
          zip.each do |entry|
            output_path = File.join(output_directory, entry.name)
            FileUtils.mkdir_p(File.dirname(output_path))
            entry.extract(output_path) unless File.exist?(output_path)
          end
        end
        output_directory
      end

      def extract_all_rar(output_directory)
        raise NotImplementedError, "RAR extraction not implemented"
      end

      def extract_all_7z(output_directory)
        raise NotImplementedError, "7z extraction not implemented"
      end

      def extract_text_files
        text_files = {}
        return text_files unless detect_archive_type == :zip
        
        Zip::File.open(@file_path) do |zip|
          zip.each do |entry|
            next if entry.directory?
            
            # Check if it's a text file
            if text_file?(entry.name)
              begin
                content = entry.get_input_stream.read
                # Try to decode as UTF-8
                text_files[entry.name] = content.force_encoding('UTF-8')
              rescue
                # Skip files that can't be read as text
              end
            end
          end
        end
        
        text_files
      end

      def text_file?(filename)
        text_extensions = %w[.txt .md .readme .log .csv .json .xml .html .css .js .rb .py .java .c .cpp .h]
        extension = File.extname(filename).downcase
        text_extensions.include?(extension) || File.basename(filename).downcase.match?(/readme|license|changelog/)
      end

      def analyze_file_types(files_list)
        type_counts = Hash.new(0)
        files_list.each do |file_info|
          next if file_info[:is_directory]
          
          extension = File.extname(file_info[:path]).downcase
          type_counts[extension.empty? ? 'no_extension' : extension] += 1
        end
        type_counts
      end

      def build_directory_structure(files_list)
        structure = {}
        files_list.each do |file_info|
          path_parts = file_info[:path].split('/')
          current = structure
          
          path_parts.each_with_index do |part, index|
            current[part] ||= {}
            current = current[part]
            
            if index == path_parts.length - 1 && !file_info[:is_directory]
              current[:_file_info] = file_info
            end
          end
        end
        structure
      end

      def has_executable_files?(files_list)
        executable_extensions = %w[.exe .bat .sh .cmd .com .scr .msi .deb .rpm .dmg .app]
        files_list.any? do |file_info|
          extension = File.extname(file_info[:path]).downcase
          executable_extensions.include?(extension)
        end
      end

      def find_largest_file(files_list)
        files_list.reject { |f| f[:is_directory] }.max_by { |f| f[:size] }
      end

      def calculate_compression_ratio
        return 0 unless detect_archive_type == :zip
        
        total_size = 0
        compressed_size = 0
        
        Zip::File.open(@file_path) do |zip|
          zip.each do |entry|
            next if entry.directory?
            total_size += entry.size
            compressed_size += entry.compressed_size
          end
        end
        
        return 0 if total_size == 0
        ((total_size - compressed_size).to_f / total_size * 100).round(2)
      rescue
        0
      end
    end
  end
end 