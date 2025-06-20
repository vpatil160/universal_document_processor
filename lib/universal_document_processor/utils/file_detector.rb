module UniversalDocumentProcessor
  module Utils
    class FileDetector
      MIME_TYPE_MAPPINGS = {
        'pdf' => 'application/pdf',
        'doc' => 'application/msword',
        'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'xls' => 'application/vnd.ms-excel',
        'xlsx' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'ppt' => 'application/vnd.ms-powerpoint',
        'pptx' => 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
        'txt' => 'text/plain',
        'rtf' => 'application/rtf',
        'html' => 'text/html',
        'htm' => 'text/html',
        'xml' => 'application/xml',
        'csv' => 'text/csv',
        'json' => 'application/json',
        'jpg' => 'image/jpeg',
        'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'gif' => 'image/gif',
        'bmp' => 'image/bmp',
        'tiff' => 'image/tiff',
        'tif' => 'image/tiff',
        'zip' => 'application/zip',
        'rar' => 'application/x-rar-compressed',
        '7z' => 'application/x-7z-compressed'
      }.freeze

      def self.detect(file_path)
        # First try Marcel for accurate MIME detection
        mime_type = Marcel::MimeType.for(Pathname.new(file_path))
        return mime_type if mime_type && mime_type != 'application/octet-stream'

        # Fallback to extension-based detection
        extension = File.extname(file_path).downcase.gsub('.', '')
        MIME_TYPE_MAPPINGS[extension] || 'application/octet-stream'
      end

      def self.supported?(file_path)
        mime_type = detect(file_path)
        supported_mime_types.include?(mime_type)
      end

      def self.supported_mime_types
        MIME_TYPE_MAPPINGS.values + [
          'application/octet-stream',
          'text/plain',
          'text/html',
          'application/xml'
        ]
      end

      def self.format_category(file_path)
        mime_type = detect(file_path)
        
        case mime_type
        when /pdf/
          :pdf
        when /word/, /document/
          :document
        when /excel/, /spreadsheet/
          :spreadsheet
        when /powerpoint/, /presentation/
          :presentation
        when /image/
          :image
        when /text/, /plain/
          :text
        when /zip/, /archive/, /compressed/
          :archive
        else
          :unknown
        end
      end

      def self.extension_from_mime(mime_type)
        MIME_TYPE_MAPPINGS.key(mime_type) || 'bin'
      end
    end
  end
end 