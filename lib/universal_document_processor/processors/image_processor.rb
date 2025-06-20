module UniversalDocumentProcessor
  module Processors
    class ImageProcessor < BaseProcessor
      def extract_text
        with_error_handling do
          # Images don't contain extractable text by default
          # This could be extended with OCR functionality
          "Image file: #{File.basename(@file_path)}"
        end
      end

      def extract_metadata
        with_error_handling do
          image = MiniMagick::Image.open(@file_path)
          
          super.merge({
            width: image.width,
            height: image.height,
            format: image.type,
            colorspace: image.colorspace,
            resolution: extract_resolution(image),
            compression: image['compression'],
            quality: image['quality'],
            exif_data: extract_exif_data(image),
            color_profile: extract_color_profile(image),
            has_transparency: has_transparency?(image)
          })
        end
      end

      def extract_colors
        with_error_handling do
          image = MiniMagick::Image.open(@file_path)
          
          # Get dominant colors using ImageMagick's histogram
          colors = []
          histogram_output = image.run_command('convert', @file_path, '-colors', '10', '-depth', '8', '-format', '%c', 'histogram:info:-')
          
          histogram_output.split("\n").each do |line|
            if line.match(/(\d+):\s+\(([^)]+)\)\s+(#\w+)/)
              count = $1.to_i
              rgb = $2
              hex = $3
              colors << {
                count: count,
                rgb: rgb,
                hex: hex
              }
            end
          end
          
          colors.sort_by { |c| -c[:count] }
        end
      rescue => e
        []
      end

      def resize(width, height, output_path = nil)
        with_error_handling do
          image = MiniMagick::Image.open(@file_path)
          image.resize "#{width}x#{height}"
          
          if output_path
            image.write(output_path)
            output_path
          else
            # Return as blob
            image.to_blob
          end
        end
      end

      def convert_format(target_format, output_path = nil)
        with_error_handling do
          image = MiniMagick::Image.open(@file_path)
          image.format(target_format.to_s.downcase)
          
          if output_path
            image.write(output_path)
            output_path
          else
            # Return as blob
            image.to_blob
          end
        end
      end

      def create_thumbnail(size = 150, output_path = nil)
        with_error_handling do
          image = MiniMagick::Image.open(@file_path)
          image.resize "#{size}x#{size}"
          
          if output_path
            image.write(output_path)
            output_path
          else
            image.to_blob
          end
        end
      end

      def extract_faces
        with_error_handling do
          # Placeholder for face detection
          # Would require additional libraries like opencv or face detection APIs
          []
        end
      end

      def extract_text_ocr
        with_error_handling do
          # Placeholder for OCR functionality
          # Would require tesseract or similar OCR library
          "OCR not implemented - would require tesseract gem"
        end
      end

      def supported_operations
        super + [:extract_colors, :resize, :convert_format, :create_thumbnail, :extract_faces, :extract_text_ocr]
      end

      private

      def extract_resolution(image)
        {
          x: image.resolution[0],
          y: image.resolution[1],
          units: image['units']
        }
      rescue
        { x: nil, y: nil, units: nil }
      end

      def extract_exif_data(image)
        exif = {}
        
        # Common EXIF tags
        exif_tags = %w[
          exif:DateTime exif:DateTimeOriginal exif:DateTimeDigitized
          exif:Make exif:Model exif:Software
          exif:ExposureTime exif:FNumber exif:ISO exif:Flash
          exif:FocalLength exif:WhiteBalance
          exif:GPSLatitude exif:GPSLongitude exif:GPSAltitude
        ]
        
        exif_tags.each do |tag|
          value = image[tag]
          exif[tag.gsub('exif:', '')] = value if value
        end
        
        exif
      rescue
        {}
      end

      def extract_color_profile(image)
        {
          profile: image['colorspace'],
          icc_profile: image['icc:description']
        }
      rescue
        {}
      end

      def has_transparency?(image)
        image['matte'] == 'True' || image.type.downcase.include?('png')
      rescue
        false
      end
    end
  end
end 