require 'set'
require 'zip'
require 'rexml/document'
require 'csv'

module UniversalDocumentProcessor
  module Processors
    class ExcelProcessor < BaseProcessor
      MAX_FILE_SIZE = 50 * 1024 * 1024 # 50 MB

      def extract_text
        validate_file
        with_error_handling do
          if @file_path.end_with?('.csv')
            # Encoding validation for CSV
            validation = UniversalDocumentProcessor.validate_file(@file_path)
            unless validation[:valid]
              return UniversalDocumentProcessor.clean_text(validation[:content], {
                remove_null_bytes: true,
                remove_control_chars: true,
                normalize_whitespace: true
              })
            end
            extract_csv_text
          elsif @file_path.end_with?('.tsv')
            # Encoding validation for TSV
            validation = UniversalDocumentProcessor.validate_file(@file_path)
            unless validation[:valid]
              return UniversalDocumentProcessor.clean_text(validation[:content], {
                remove_null_bytes: true,
                remove_control_chars: true,
                normalize_whitespace: true
              })
            end
            extract_tsv_text
          elsif @file_path.end_with?('.xlsx')
            extract_xlsx_text_builtin
          elsif @file_path.end_with?('.xls')
            extract_xls_text_builtin
          else
            determine_format_and_extract
          end
        end
      end

      def extract_metadata
        with_error_handling do
          if @file_path.end_with?('.csv')
            extract_csv_metadata
          elsif @file_path.end_with?('.tsv')
            extract_tsv_metadata
          elsif @file_path.end_with?('.xlsx')
            extract_xlsx_metadata_builtin
          elsif @file_path.end_with?('.xls')
            extract_xls_metadata_builtin
          else
            basic_file_metadata
          end
        end
      end

      def extract_tables
        with_error_handling do
          if @file_path.end_with?('.csv')
            extract_csv_tables
          elsif @file_path.end_with?('.tsv')
            extract_tsv_tables
          elsif @file_path.end_with?('.xlsx')
            extract_xlsx_tables_builtin
          elsif @file_path.end_with?('.xls')
            extract_xls_tables_builtin
          else
            []
          end
        end
      end

      def extract_formulas
        with_error_handling do
          if @file_path.end_with?('.xlsx')
            extract_xlsx_formulas_builtin
          else
            # .xls, .csv, and .tsv don't support formulas in our built-in implementation
            []
          end
        end
      end

      def extract_charts
        with_error_handling do
          # Chart extraction would require more complex parsing
          # This is a placeholder for future implementation
          []
        end
      end

      def supported_operations
        super + [:extract_tables, :extract_formulas, :extract_charts, :extract_pivot_tables, :extract_statistics, :extract_cell_formatting, :validate_data, :to_csv, :to_tsv, :to_json]
      end

      def to_csv(sheet_name = nil)
        with_error_handling do
          if @file_path.end_with?('.csv')
            File.read(@file_path)
          elsif @file_path.end_with?('.tsv')
            # Convert TSV to CSV
            convert_tsv_to_csv(File.read(@file_path))
          else
            tables = extract_tables
            if sheet_name
              table = tables.find { |t| t[:sheet_name] == sheet_name }
              return "" unless table
              convert_table_to_csv(table)
            else
              # Convert all sheets to CSV
              csv_data = {}
              tables.each do |table|
                csv_data[table[:sheet_name]] = convert_table_to_csv(table)
              end
              csv_data
            end
          end
        end
      end

      def to_tsv(sheet_name = nil)
        with_error_handling do
          if @file_path.end_with?('.tsv')
            File.read(@file_path)
          elsif @file_path.end_with?('.csv')
            # Convert CSV to TSV
            convert_csv_to_tsv(File.read(@file_path))
          else
            tables = extract_tables
            if sheet_name
              table = tables.find { |t| t[:sheet_name] == sheet_name }
              return "" unless table
              convert_table_to_tsv(table)
            else
              # Convert all sheets to TSV
              tsv_data = {}
              tables.each do |table|
                tsv_data[table[:sheet_name]] = convert_table_to_tsv(table)
              end
              tsv_data
            end
          end
        end
      end

      def to_json
        with_error_handling do
          tables = extract_tables
          json_data = {}
          
          tables.each do |table|
            sheet_data = []
            headers = table[:headers] || []
            
            table[:data].each_with_index do |row, index|
              next if index == 0 && !headers.empty? # Skip header row if we have headers
              
              row_hash = {}
              row.each_with_index do |cell, col_index|
                header = headers[col_index] || "Column #{col_index + 1}"
                row_hash[header] = cell
              end
              sheet_data << row_hash
            end
            
            json_data[table[:sheet_name]] = sheet_data
          end
          
          require 'json'
          json_data.to_json
        end
      end

      def extract_statistics
        with_error_handling do
          tables = extract_tables
          statistics = {}
          
          tables.each do |table|
            sheet_stats = analyze_table_statistics(table)
            statistics[table[:sheet_name]] = sheet_stats
          end
          
          statistics
        end
      end

      def validate_data
        with_error_handling do
          tables = extract_tables
          validation_results = {}
          
          tables.each do |table|
            validation = validate_table_data(table)
            validation_results[table[:sheet_name]] = validation
          end
          
          validation_results
        end
      end

      def extract_cell_formatting
        with_error_handling do
          # This would require more detailed Excel parsing
          # For now, return basic formatting info for built-in processing
          {
            note: "Cell formatting extraction requires more detailed Excel parsing - feature planned for future release"
          }
        end
      end

      def create_summary_report
        with_error_handling do
          {
            metadata: extract_metadata,
            statistics: extract_statistics,
            data_validation: validate_data,
            formulas: extract_formulas.length,
            total_sheets: extract_metadata[:sheet_count],
            processing_time: Time.current.to_s
          }
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

      # CSV Processing Methods
      def extract_csv_text
        content = File.read(@file_path, encoding: 'UTF-8')
        # Convert CSV to readable text format
        lines = CSV.parse(content)
        lines.map { |row| row.join(' | ') }.join("\n")
      rescue => e
        "Error reading CSV: #{e.message}"
      end

      def extract_csv_metadata
        content = File.read(@file_path, encoding: 'UTF-8')
        lines = CSV.parse(content)
        
        {
          format: 'csv',
          file_size: File.size(@file_path),
          last_modified: File.mtime(@file_path),
          sheet_count: 1,
          sheet_names: ['Sheet1'],
          total_rows: lines.length,
          total_columns: lines.first&.length || 0,
          has_headers: detect_csv_headers(lines),
          encoding: 'UTF-8'
        }
      rescue => e
        basic_file_metadata.merge(error: e.message)
      end

      def extract_csv_tables
        content = File.read(@file_path, encoding: 'UTF-8')
        lines = CSV.parse(content)
        
        headers = detect_csv_headers(lines) ? lines.first : []
        
        [{
          sheet_name: 'Sheet1',
          rows: lines.length,
          columns: lines.first&.length || 0,
          headers: headers,
          data: lines
        }]
      rescue => e
        []
      end

      def detect_csv_headers(lines)
        return false if lines.empty? || lines.length < 2
        
        first_row = lines.first
        second_row = lines[1]
        
        # Check if first row contains text and second row contains different data types
        first_row.any? { |cell| cell.to_s.match?(/[a-zA-Z]/) } &&
        second_row.any? { |cell| cell.to_s.match?(/^\d+$/) || cell.to_s.match?(/^\d+\.\d+$/) }
      end

      # TSV Processing Methods
      def extract_tsv_text
        content = File.read(@file_path, encoding: 'UTF-8')
        # Convert TSV to readable text format
        lines = CSV.parse(content, col_sep: "\t")
        lines.map { |row| row.join(' | ') }.join("\n")
      rescue => e
        "Error reading TSV: #{e.message}"
      end

      def extract_tsv_metadata
        content = File.read(@file_path, encoding: 'UTF-8')
        lines = CSV.parse(content, col_sep: "\t")
        
        {
          format: 'tsv',
          file_size: File.size(@file_path),
          last_modified: File.mtime(@file_path),
          sheet_count: 1,
          sheet_names: ['Sheet1'],
          total_rows: lines.length,
          total_columns: lines.first&.length || 0,
          has_headers: detect_tsv_headers(lines),
          encoding: 'UTF-8',
          delimiter: 'tab'
        }
      rescue => e
        basic_file_metadata.merge(error: e.message)
      end

      def extract_tsv_tables
        content = File.read(@file_path, encoding: 'UTF-8')
        lines = CSV.parse(content, col_sep: "\t")
        
        headers = detect_tsv_headers(lines) ? lines.first : []
        
        [{
          sheet_name: 'Sheet1',
          rows: lines.length,
          columns: lines.first&.length || 0,
          headers: headers,
          data: lines
        }]
      rescue => e
        []
      end

      def detect_tsv_headers(lines)
        return false if lines.empty? || lines.length < 2
        
        first_row = lines.first
        second_row = lines[1]
        
        # Check if first row contains text and second row contains different data types
        first_row.any? { |cell| cell.to_s.match?(/[a-zA-Z]/) } &&
        second_row.any? { |cell| cell.to_s.match?(/^\d+$/) || cell.to_s.match?(/^\d+\.\d+$/) }
      end

      # XLSX Processing Methods (ZIP-based)
      def extract_xlsx_text_builtin
        text_content = []
        
        Zip::File.open(@file_path) do |zip_file|
          # Get shared strings
          shared_strings = extract_shared_strings(zip_file)
          
          # Get worksheet files
          worksheet_files = zip_file.entries.select { |entry| entry.name.match?(/xl\/worksheets\/sheet\d+\.xml/) }
          
          worksheet_files.each_with_index do |worksheet_file, index|
            sheet_name = "Sheet#{index + 1}"
            text_content << "=== #{sheet_name} ==="
            
            worksheet_xml = zip_file.read(worksheet_file)
            sheet_text = extract_text_from_worksheet_xml(worksheet_xml, shared_strings)
            text_content << sheet_text
            text_content << ""
          end
        end
        
        text_content.join("\n")
      rescue => e
        "Error reading XLSX file: #{e.message}"
      end

      def extract_xlsx_metadata_builtin
        metadata = basic_file_metadata
        
        Zip::File.open(@file_path) do |zip_file|
          worksheet_files = zip_file.entries.select { |entry| entry.name.match?(/xl\/worksheets\/sheet\d+\.xml/) }
          
          metadata.merge!({
            format: 'xlsx',
            sheet_count: worksheet_files.length,
            sheet_names: worksheet_files.map.with_index { |_, i| "Sheet#{i + 1}" },
            has_formulas: detect_xlsx_formulas(zip_file),
            has_shared_strings: zip_file.entries.any? { |entry| entry.name == 'xl/sharedStrings.xml' }
          })
        end
        
        metadata
      rescue => e
        basic_file_metadata.merge(error: e.message)
      end

      def extract_xlsx_tables_builtin
        tables = []
        
        Zip::File.open(@file_path) do |zip_file|
          shared_strings = extract_shared_strings(zip_file)
          worksheet_files = zip_file.entries.select { |entry| entry.name.match?(/xl\/worksheets\/sheet\d+\.xml/) }
          
          worksheet_files.each_with_index do |worksheet_file, index|
            sheet_name = "Sheet#{index + 1}"
            worksheet_xml = zip_file.read(worksheet_file)
            
            table_data = extract_table_from_worksheet_xml(worksheet_xml, shared_strings)
            table_data[:sheet_name] = sheet_name
            tables << table_data
          end
        end
        
        tables
      rescue => e
        []
      end

      def extract_xlsx_formulas_builtin
        formulas = []
        
        Zip::File.open(@file_path) do |zip_file|
          worksheet_files = zip_file.entries.select { |entry| entry.name.match?(/xl\/worksheets\/sheet\d+\.xml/) }
          
          worksheet_files.each_with_index do |worksheet_file, index|
            sheet_name = "Sheet#{index + 1}"
            worksheet_xml = zip_file.read(worksheet_file)
            
            sheet_formulas = extract_formulas_from_worksheet_xml(worksheet_xml, sheet_name)
            formulas.concat(sheet_formulas)
          end
        end
        
        formulas
      rescue => e
        []
      end

      def extract_shared_strings(zip_file)
        shared_strings = []
        
        shared_strings_entry = zip_file.entries.find { |entry| entry.name == 'xl/sharedStrings.xml' }
        return shared_strings unless shared_strings_entry
        
        shared_strings_xml = zip_file.read(shared_strings_entry)
        doc = REXML::Document.new(shared_strings_xml)
        
        doc.elements.each('sst/si') do |si|
          text_elements = si.get_elements('t')
          if text_elements.any?
            shared_strings << text_elements.first.text
          else
            # Handle rich text
            rich_text = si.get_elements('r/t').map(&:text).join
            shared_strings << rich_text
          end
        end
        
        shared_strings
      rescue => e
        []
      end

      def extract_text_from_worksheet_xml(worksheet_xml, shared_strings)
        doc = REXML::Document.new(worksheet_xml)
        rows = []
        
        doc.elements.each('worksheet/sheetData/row') do |row|
          row_data = []
          row.elements.each('c') do |cell|
            cell_value = extract_cell_value(cell, shared_strings)
            row_data << cell_value
          end
          rows << row_data.join(' | ') unless row_data.all?(&:empty?)
        end
        
        rows.join("\n")
      end

      def extract_table_from_worksheet_xml(worksheet_xml, shared_strings)
        doc = REXML::Document.new(worksheet_xml)
        data = []
        max_columns = 0
        
        doc.elements.each('worksheet/sheetData/row') do |row|
          row_data = []
          row.elements.each('c') do |cell|
            cell_value = extract_cell_value(cell, shared_strings)
            row_data << cell_value
          end
          data << row_data
          max_columns = [max_columns, row_data.length].max
        end
        
        # Normalize row lengths
        data.each { |row| row.fill('', row.length...max_columns) }
        
        headers = data.first || []
        
        {
          rows: data.length,
          columns: max_columns,
          headers: headers,
          data: data
        }
      end

      def extract_formulas_from_worksheet_xml(worksheet_xml, sheet_name)
        doc = REXML::Document.new(worksheet_xml)
        formulas = []
        
        doc.elements.each('worksheet/sheetData/row') do |row|
          row_num = row.attributes['r'].to_i
          
          row.elements.each('c') do |cell|
            cell_ref = cell.attributes['r']
            formula_element = cell.elements['f']
            
            if formula_element && formula_element.text
              formulas << {
                sheet: sheet_name,
                cell: cell_ref,
                formula: formula_element.text,
                value: extract_cell_value(cell, [])
              }
            end
          end
        end
        
        formulas
      end

      def extract_cell_value(cell, shared_strings)
        cell_type = cell.attributes['t']
        value_element = cell.elements['v']
        
        return '' unless value_element && value_element.text
        
        case cell_type
        when 's' # Shared string
          index = value_element.text.to_i
          shared_strings[index] || ''
        when 'str' # String
          value_element.text
        when 'b' # Boolean
          value_element.text == '1' ? 'TRUE' : 'FALSE'
        else # Number or date
          value_element.text
        end
      end

      def detect_xlsx_formulas(zip_file)
        worksheet_files = zip_file.entries.select { |entry| entry.name.match?(/xl\/worksheets\/sheet\d+\.xml/) }
        
        worksheet_files.any? do |worksheet_file|
          worksheet_xml = zip_file.read(worksheet_file)
          worksheet_xml.include?('<f>')
        end
      end

      # XLS Processing Methods (Binary format - basic implementation)
      def extract_xls_text_builtin
        # Basic XLS text extraction - this is a simplified implementation
        # For full XLS support, a more complex binary parser would be needed
        content = File.binread(@file_path)
        
        # Try to extract readable text from the binary data
        text_parts = content.scan(/[\x20-\x7E]{3,}/).uniq
        
        if text_parts.any?
          "=== XLS Content (Basic Extraction) ===\n" + text_parts.join("\n")
        else
          "XLS file detected but no readable text extracted. Consider converting to XLSX format for better support."
        end
      rescue => e
        "Error reading XLS file: #{e.message}"
      end

      def extract_xls_metadata_builtin
        basic_file_metadata.merge({
          format: 'xls',
          sheet_count: 1,
          sheet_names: ['Sheet1'],
          note: 'XLS format has limited built-in support. Consider converting to XLSX for full functionality.'
        })
      end

      def extract_xls_tables_builtin
        [{
          sheet_name: 'Sheet1',
          rows: 0,
          columns: 0,
          headers: [],
          data: [],
          note: 'XLS format has limited built-in support. Consider converting to XLSX for full functionality.'
        }]
      end

      # Helper Methods
      def determine_format_and_extract
        # Try to determine format by content
        if File.binread(@file_path, 4) == "PK\x03\x04"
          extract_xlsx_text_builtin
        else
          extract_xls_text_builtin
        end
      end

      def basic_file_metadata
        {
          file_size: File.size(@file_path),
          last_modified: File.mtime(@file_path),
          created: File.ctime(@file_path),
          format: File.extname(@file_path).downcase.gsub('.', ''),
          encoding: 'Unknown'
        }
      end

      def convert_table_to_csv(table)
        require 'csv'
        
        CSV.generate do |csv|
          table[:data].each do |row|
            csv << row
          end
        end
      end

      def convert_table_to_tsv(table)
        require 'csv'
        
        CSV.generate(col_sep: "\t") do |tsv|
          table[:data].each do |row|
            tsv << row
          end
        end
      end

      def convert_csv_to_tsv(csv_content)
        require 'csv'
        
        lines = CSV.parse(csv_content)
        CSV.generate(col_sep: "\t") do |tsv|
          lines.each do |row|
            tsv << row
          end
        end
      end

      def convert_tsv_to_csv(tsv_content)
        require 'csv'
        
        lines = CSV.parse(tsv_content, col_sep: "\t")
        CSV.generate do |csv|
          lines.each do |row|
            csv << row
          end
        end
      end

      def analyze_table_statistics(table)
        return {} if table[:data].empty?
        
        stats = {
          total_cells: table[:rows] * table[:columns],
          empty_cells: 0,
          numeric_cells: 0,
          text_cells: 0,
          numeric_values: []
        }
        
        table[:data].each do |row|
          row.each do |cell|
            if cell.nil? || cell.to_s.strip.empty?
              stats[:empty_cells] += 1
            elsif cell.to_s.match?(/^\d+(\.\d+)?$/)
              stats[:numeric_cells] += 1
              stats[:numeric_values] << cell.to_f
            else
              stats[:text_cells] += 1
            end
          end
        end
        
        if stats[:numeric_values].any?
          values = stats[:numeric_values]
          stats[:min_value] = values.min
          stats[:max_value] = values.max
          stats[:average_value] = values.sum / values.length.to_f
          stats[:median_value] = calculate_median(values)
        end
        
        stats
      end

      def validate_table_data(table)
        return {} if table[:data].empty?
        
        validation = {
          total_rows: table[:rows],
          empty_rows: 0,
          duplicate_rows: 0,
          data_quality_score: 0
        }
        
        seen_rows = Set.new
        
        table[:data].each do |row|
          if row.all? { |cell| cell.nil? || cell.to_s.strip.empty? }
            validation[:empty_rows] += 1
          end
          
          row_key = row.join('|')
          if seen_rows.include?(row_key)
            validation[:duplicate_rows] += 1
          else
            seen_rows.add(row_key)
          end
        end
        
        # Calculate data quality score (0-100)
        total_rows = table[:rows]
        if total_rows > 0
          quality_score = ((total_rows - validation[:empty_rows] - validation[:duplicate_rows]) / total_rows.to_f) * 100
          validation[:data_quality_score] = [quality_score.round(2), 0].max
        end
        
        validation
      end

      def calculate_median(values)
        sorted = values.sort
        mid = sorted.length / 2
        
        if sorted.length.odd?
          sorted[mid]
        else
          (sorted[mid - 1] + sorted[mid]) / 2.0
        end
      end

      def detect_formulas(workbook)
        workbook.sheets.any? do |sheet_name|
          workbook.sheet(sheet_name)
          next false unless workbook.last_row
          
          (workbook.first_row..workbook.last_row).any? do |row|
            (workbook.first_column..workbook.last_column).any? do |col|
              workbook.respond_to?(:formula) && workbook.formula(row, col)
            end
          end
        end
      rescue
        false
      end

      def detect_charts(workbook)
        # Chart detection would require more complex parsing
        # This is a placeholder for future implementation
        false
      end

      def calculate_median(values)
        sorted = values.sort
        length = sorted.length
        if length.odd?
          sorted[length / 2]
        else
          (sorted[length / 2 - 1] + sorted[length / 2]) / 2.0
        end
      end

      def detect_headers(workbook)
        return false unless workbook.last_row && workbook.last_row > 1
        
        # Check if first row contains mostly text while second row contains numbers
        first_row_types = []
        second_row_types = []
        
        (workbook.first_column..workbook.last_column).each do |col|
          first_cell = workbook.cell(workbook.first_row, col)
          second_cell = workbook.cell(workbook.first_row + 1, col)
          
          first_row_types << (first_cell.is_a?(String) ? :text : :other)
          second_row_types << (second_cell.is_a?(Numeric) ? :numeric : :other)
        end
        
        # If first row is mostly text and second row has numbers, likely has headers
        text_ratio = first_row_types.count(:text).to_f / first_row_types.length
        numeric_ratio = second_row_types.count(:numeric).to_f / second_row_types.length
        
        text_ratio > 0.5 && numeric_ratio > 0.3
      end

      def analyze_column_types(workbook)
        return {} unless workbook.last_row
        
        column_types = {}
        
        (workbook.first_column..workbook.last_column).each do |col|
          types = { numeric: 0, text: 0, date: 0, empty: 0 }
          total_rows = workbook.last_row - workbook.first_row + 1
          
          (workbook.first_row..workbook.last_row).each do |row|
            cell_value = workbook.cell(row, col)
            
            if cell_value.nil? || cell_value.to_s.strip.empty?
              types[:empty] += 1
            elsif cell_value.is_a?(Numeric)
              types[:numeric] += 1
            elsif cell_value.is_a?(Date) || cell_value.is_a?(Time)
              types[:date] += 1
            else
              types[:text] += 1
            end
          end
          
          # Determine predominant type
          max_type = types.max_by { |k, v| v }
          column_types["Column #{col}"] = {
            predominant_type: max_type[0],
            type_distribution: types.transform_values { |v| (v.to_f / total_rows * 100).round(1) }
          }
        end
        
        column_types
      end
    end
  end
end 