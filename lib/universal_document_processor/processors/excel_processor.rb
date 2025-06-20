module UniversalDocumentProcessor
  module Processors
    class ExcelProcessor < BaseProcessor
      def extract_text
        with_error_handling do
          workbook = Roo::Spreadsheet.open(@file_path)
          text_content = []
          
          workbook.sheets.each do |sheet_name|
            workbook.sheet(sheet_name)
            text_content << "=== Sheet: #{sheet_name} ==="
            
            # Get all rows with data
            if workbook.last_row
              (workbook.first_row..workbook.last_row).each do |row|
                row_data = []
                (workbook.first_column..workbook.last_column).each do |col|
                  cell_value = workbook.cell(row, col)
                  row_data << cell_value.to_s if cell_value
                end
                text_content << row_data.join(' | ') unless row_data.all?(&:empty?)
              end
            end
            
            text_content << "" # Add blank line between sheets
          end
          
          text_content.join("\n")
        end
      end

      def extract_metadata
        with_error_handling do
          workbook = Roo::Spreadsheet.open(@file_path)
          
          sheet_info = {}
          workbook.sheets.each do |sheet_name|
            workbook.sheet(sheet_name)
            sheet_info[sheet_name] = {
              rows: workbook.last_row || 0,
              columns: workbook.last_column || 0,
              first_row: workbook.first_row || 0,
              first_column: workbook.first_column || 0
            }
          end
          
          super.merge({
            sheet_count: workbook.sheets.length,
            sheet_names: workbook.sheets,
            sheet_info: sheet_info,
            total_rows: sheet_info.values.sum { |info| info[:rows] },
            total_columns: sheet_info.values.map { |info| info[:columns] }.max || 0,
            has_formulas: detect_formulas(workbook),
            has_charts: detect_charts(workbook)
          })
        end
      end

      def extract_tables
        with_error_handling do
          workbook = Roo::Spreadsheet.open(@file_path)
          tables = []
          
          workbook.sheets.each do |sheet_name|
            workbook.sheet(sheet_name)
            next unless workbook.last_row
            
            table_data = {
              sheet_name: sheet_name,
              rows: workbook.last_row,
              columns: workbook.last_column,
              data: [],
              headers: []
            }
            
            # Extract headers (first row)
            if workbook.first_row
              (workbook.first_column..workbook.last_column).each do |col|
                header = workbook.cell(workbook.first_row, col)
                table_data[:headers] << (header ? header.to_s : "Column #{col}")
              end
            end
            
            # Extract all data
            (workbook.first_row..workbook.last_row).each do |row|
              row_data = []
              (workbook.first_column..workbook.last_column).each do |col|
                cell_value = workbook.cell(row, col)
                row_data << (cell_value ? cell_value.to_s : "")
              end
              table_data[:data] << row_data
            end
            
            tables << table_data
          end
          
          tables
        end
      end

      def extract_formulas
        with_error_handling do
          workbook = Roo::Spreadsheet.open(@file_path)
          formulas = []
          
          workbook.sheets.each do |sheet_name|
            workbook.sheet(sheet_name)
            next unless workbook.last_row
            
            (workbook.first_row..workbook.last_row).each do |row|
              (workbook.first_column..workbook.last_column).each do |col|
                if workbook.respond_to?(:formula) && workbook.formula(row, col)
                  formulas << {
                    sheet: sheet_name,
                    row: row,
                    column: col,
                    formula: workbook.formula(row, col),
                    value: workbook.cell(row, col)
                  }
                end
              end
            end
          end
          
          formulas
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
        super + [:extract_tables, :extract_formulas, :extract_charts, :extract_pivot_tables]
      end

      def to_csv(sheet_name = nil)
        with_error_handling do
          workbook = Roo::Spreadsheet.open(@file_path)
          
          if sheet_name
            workbook.sheet(sheet_name)
            workbook.to_csv
          else
            # Convert all sheets to CSV
            csv_data = {}
            workbook.sheets.each do |name|
              workbook.sheet(name)
              csv_data[name] = workbook.to_csv
            end
            csv_data
          end
        end
      end

      def to_json
        with_error_handling do
          workbook = Roo::Spreadsheet.open(@file_path)
          json_data = {}
          
          workbook.sheets.each do |sheet_name|
            workbook.sheet(sheet_name)
            sheet_data = []
            
            next unless workbook.last_row
            
            # Get headers
            headers = []
            (workbook.first_column..workbook.last_column).each do |col|
              header = workbook.cell(workbook.first_row, col)
              headers << (header ? header.to_s : "Column #{col}")
            end
            
            # Get data rows
            ((workbook.first_row + 1)..workbook.last_row).each do |row|
              row_hash = {}
              (workbook.first_column..workbook.last_column).each_with_index do |col, index|
                cell_value = workbook.cell(row, col)
                row_hash[headers[index]] = cell_value
              end
              sheet_data << row_hash
            end
            
            json_data[sheet_name] = sheet_data
          end
          
          json_data.to_json
        end
      end

      private

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
    end
  end
end 