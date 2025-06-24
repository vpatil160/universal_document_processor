# Coverage setup (must be first)
if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start do
    add_filter '/test/'
    add_filter '/vendor/'
    coverage_dir 'coverage'
  end
end

require 'minitest/autorun'
require 'minitest/pride'
require 'minitest/reporters'
require 'tempfile'
require 'fileutils'

# Use better test output
Minitest::Reporters.use! [Minitest::Reporters::SpecReporter.new]

# Add lib directory to load path
$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

# Load the gem
require 'universal_document_processor'

class Minitest::Test
  # Helper method to create temporary files for testing
  def create_temp_file(content, extension = '.txt')
    file = Tempfile.new(['test', extension])
    file.write(content)
    file.close
    file.path
  end

  # Helper method to create sample files for testing
  def create_sample_files
    @sample_files = {}
    
    # Text file
    @sample_files[:txt] = create_temp_file("This is a sample text file.\nIt has multiple lines.\nUsed for testing.")
    
    # CSV file
    csv_content = "Name,Age,City\nJohn,25,New York\nJane,30,Los Angeles\nBob,35,Chicago"
    @sample_files[:csv] = create_temp_file(csv_content, '.csv')
    
    # TSV file
    tsv_content = "Name\tAge\tCity\nJohn\t25\tNew York\nJane\t30\tLos Angeles\nBob\t35\tChicago"
    @sample_files[:tsv] = create_temp_file(tsv_content, '.tsv')
    
    # JSON file
    json_content = '{"name": "Test Document", "type": "sample", "data": [1, 2, 3, 4, 5]}'
    @sample_files[:json] = create_temp_file(json_content, '.json')
    
    # XML file
    xml_content = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <document>
        <title>Sample XML Document</title>
        <content>This is a sample XML file for testing.</content>
        <metadata>
          <author>Test Author</author>
          <date>2024-01-01</date>
        </metadata>
      </document>
    XML
    @sample_files[:xml] = create_temp_file(xml_content, '.xml')
    
    # HTML file
    html_content = <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <title>Sample HTML Document</title>
      </head>
      <body>
        <h1>Test Document</h1>
        <p>This is a sample HTML file for testing.</p>
        <ul>
          <li>Item 1</li>
          <li>Item 2</li>
          <li>Item 3</li>
        </ul>
      </body>
      </html>
    HTML
    @sample_files[:html] = create_temp_file(html_content, '.html')
  end

  # Clean up temporary files
  def cleanup_sample_files
    @sample_files&.each do |_, file_path|
      File.delete(file_path) if File.exist?(file_path)
    end
  end

  # Helper to check if AI is available
  def ai_available?
    ENV['OPENAI_API_KEY'] && !ENV['OPENAI_API_KEY'].empty?
  end

  # Skip AI tests if no API key
  def skip_unless_ai_available
    skip "AI tests require OPENAI_API_KEY environment variable" unless ai_available?
  end
end 