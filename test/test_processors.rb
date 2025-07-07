require_relative 'test_helper'

class TestProcessors < Minitest::Test
  def setup
    create_sample_files
  end

  def teardown
    cleanup_sample_files
  end

  def test_text_processor
    processor = UniversalDocumentProcessor::Processors::TextProcessor.new
    
    # Test text extraction
    text = processor.extract_text(@sample_files[:txt])
    assert text.is_a?(String)
    assert text.include?("sample text file")
    
    # Test metadata
    metadata = processor.extract_metadata(@sample_files[:txt])
    assert metadata.is_a?(Hash)
    assert_equal "txt", metadata[:format]
    assert metadata.has_key?(:file_size)
    assert metadata.has_key?(:encoding)
    
    # Test processing
    result = processor.process(@sample_files[:txt])
    assert result.is_a?(Hash)
    assert result.has_key?(:text)
    assert result.has_key?(:metadata)
  end

  def test_excel_processor_csv
    processor = UniversalDocumentProcessor::Processors::ExcelProcessor.new
    
    # Test CSV processing
    text = processor.extract_text(@sample_files[:csv])
    assert text.is_a?(String)
    assert text.include?("Name")
    assert text.include?("John")
    
    # Test CSV metadata
    metadata = processor.extract_metadata(@sample_files[:csv])
    assert metadata.is_a?(Hash)
    assert_equal "csv", metadata[:format]
    assert_equal "comma", metadata[:delimiter]
    
    # Test CSV tables
    tables = processor.extract_tables(@sample_files[:csv])
    assert tables.is_a?(Array)
    assert tables.length > 0
    assert tables.first.is_a?(Hash)
    assert tables.first.has_key?(:headers)
    assert tables.first.has_key?(:rows)
  end

  def test_excel_processor_tsv
    processor = UniversalDocumentProcessor::Processors::ExcelProcessor.new
    
    # Test TSV processing
    text = processor.extract_text(@sample_files[:tsv])
    assert text.is_a?(String)
    assert text.include?("Name")
    assert text.include?("John")
    
    # Test TSV metadata
    metadata = processor.extract_metadata(@sample_files[:tsv])
    assert metadata.is_a?(Hash)
    assert_equal "tsv", metadata[:format]
    assert_equal "tab", metadata[:delimiter]
    
    # Test TSV tables
    tables = processor.extract_tables(@sample_files[:tsv])
    assert tables.is_a?(Array)
    assert tables.length > 0
    assert tables.first.is_a?(Hash)
    assert tables.first.has_key?(:headers)
    assert tables.first.has_key?(:rows)
  end

  def test_excel_processor_conversions
    processor = UniversalDocumentProcessor::Processors::ExcelProcessor.new
    
    # Test CSV to TSV conversion
    csv_content = processor.convert_csv_to_tsv(@sample_files[:csv])
    assert csv_content.is_a?(String)
    assert csv_content.include?("\t") # Should contain tabs
    
    # Test TSV to CSV conversion
    tsv_content = processor.convert_tsv_to_csv(@sample_files[:tsv])
    assert tsv_content.is_a?(String)
    assert tsv_content.include?(",") # Should contain commas
  end

  def test_character_validator
    validator = UniversalDocumentProcessor::Processors::CharacterValidator
    
    # Test text analysis
    good_text = "This is clean text."
    analysis = validator.analyze_text(good_text)
    assert analysis.is_a?(Hash)
    assert analysis.has_key?(:valid_characters)
    assert analysis.has_key?(:invalid_characters)
    assert analysis.has_key?(:character_count)
    assert analysis[:valid_characters] > 0
    assert_equal 0, analysis[:invalid_characters]
    
    # Test with invalid characters
    bad_text = "Text with\x00null\x01characters"
    bad_analysis = validator.analyze_text(bad_text)
    assert bad_analysis[:invalid_characters] > 0
    
    # Test text cleaning
    cleaned = validator.clean_text(bad_text)
    assert cleaned.is_a?(String)
    refute cleaned.include?("\x00")
    refute cleaned.include?("\x01")
    
    # Test Japanese text detection
    japanese_text = "これは日本語です"
    english_text = "This is English"
    
    assert validator.is_japanese_text?(japanese_text)
    refute validator.is_japanese_text?(english_text)
    
    # Test Japanese text validation
    japanese_validation = validator.validate_japanese_text(japanese_text)
    assert japanese_validation.is_a?(Hash)
    assert japanese_validation.has_key?(:is_japanese)
    assert japanese_validation[:is_japanese]
  end

  def test_file_detector
    detector = UniversalDocumentProcessor::Utils::FileDetector
    
    # Test MIME type detection
    txt_mime = detector.detect_mime_type(@sample_files[:txt])
    assert_equal "text/plain", txt_mime
    
    csv_mime = detector.detect_mime_type(@sample_files[:csv])
    assert_equal "text/csv", csv_mime
    
    tsv_mime = detector.detect_mime_type(@sample_files[:tsv])
    assert_equal "text/tab-separated-values", tsv_mime
    
    json_mime = detector.detect_mime_type(@sample_files[:json])
    assert_equal "application/json", json_mime
    
    # Test format detection
    txt_format = detector.detect_format(@sample_files[:txt])
    assert_equal "txt", txt_format
    
    csv_format = detector.detect_format(@sample_files[:csv])
    assert_equal "csv", csv_format
    
    tsv_format = detector.detect_format(@sample_files[:tsv])
    assert_equal "tsv", tsv_format
  end

  def test_japanese_filename_handler
    handler = UniversalDocumentProcessor::Utils::JapaneseFilenameHandler
    
    # Test Japanese detection
    japanese_filename = "テスト_ファイル.txt"
    english_filename = "test_file.txt"
    
    assert handler.contains_japanese?(japanese_filename)
    refute handler.contains_japanese?(english_filename)
    
    # Test filename validation
    validation = handler.validate_filename(japanese_filename)
    assert validation.is_a?(Hash)
    assert validation.has_key?(:valid)
    assert validation.has_key?(:contains_japanese)
    assert validation[:contains_japanese]
    
    # Test safe filename generation
    safe_name = handler.safe_filename(japanese_filename)
    assert safe_name.is_a?(String)
    refute safe_name.empty?
    
    # Test normalization
    normalized = handler.normalize_filename(japanese_filename)
    assert normalized.is_a?(String)
    refute normalized.empty?
  end

  def test_document_class_integration
    # Test Document class with various file types
    txt_doc = UniversalDocumentProcessor::Document.new(@sample_files[:txt])
    assert txt_doc.is_a?(UniversalDocumentProcessor::Document)
    
    txt_result = txt_doc.process
    assert txt_result.is_a?(Hash)
    assert txt_result.has_key?(:text)
    assert txt_result.has_key?(:metadata)
    
    # Test CSV document
    csv_doc = UniversalDocumentProcessor::Document.new(@sample_files[:csv])
    csv_result = csv_doc.process
    assert csv_result.is_a?(Hash)
    assert csv_result.has_key?(:tables)
    
    # Test TSV document
    tsv_doc = UniversalDocumentProcessor::Document.new(@sample_files[:tsv])
    tsv_result = tsv_doc.process
    assert tsv_result.is_a?(Hash)
    assert tsv_result.has_key?(:tables)
    assert_equal "tsv", tsv_result[:metadata][:format]
    
    # Test format conversion
    csv_from_tsv = tsv_doc.convert_to(:csv)
    assert csv_from_tsv.is_a?(String)
    assert csv_from_tsv.include?(",")
    
    tsv_from_csv = csv_doc.convert_to(:tsv)
    assert tsv_from_csv.is_a?(String)
    assert tsv_from_csv.include?("\t")
  end

  def test_error_handling
    # Test with non-existent file
    assert_raises(Errno::ENOENT) do
      UniversalDocumentProcessor::Document.new("non_existent_file.txt").process
    end
    
    # Test with unsupported format
    unsupported_file = create_temp_file("test content", ".unsupported")
    assert_raises(UniversalDocumentProcessor::UnsupportedFormatError) do
      UniversalDocumentProcessor::Document.new(unsupported_file).process
    end
    File.delete(unsupported_file)
  end

  def test_processor_selection
    # Test that correct processors are selected for different file types
    txt_doc = UniversalDocumentProcessor::Document.new(@sample_files[:txt])
    assert txt_doc.send(:select_processor).is_a?(UniversalDocumentProcessor::Processors::TextProcessor)
    
    csv_doc = UniversalDocumentProcessor::Document.new(@sample_files[:csv])
    assert csv_doc.send(:select_processor).is_a?(UniversalDocumentProcessor::Processors::ExcelProcessor)
    
    tsv_doc = UniversalDocumentProcessor::Document.new(@sample_files[:tsv])
    assert tsv_doc.send(:select_processor).is_a?(UniversalDocumentProcessor::Processors::ExcelProcessor)
  end

  def test_archive_processor_create_zip
    archive_class = UniversalDocumentProcessor::Processors::ArchiveProcessor
    require 'zip'
    require 'tmpdir'

    Dir.mktmpdir do |tmpdir|
      # Create some sample files
      file1 = File.join(tmpdir, 'file1.txt')
      file2 = File.join(tmpdir, 'file2.txt')
      File.write(file1, 'Hello from file1')
      File.write(file2, 'Hello from file2')

      # Test zipping a directory
      zip_path = File.join(tmpdir, 'archive_dir.zip')
      archive_class.create_zip(zip_path, tmpdir)
      assert File.exist?(zip_path)
      entries = []
      Zip::File.open(zip_path) { |zip| zip.each { |e| entries << e.name } }
      assert_includes entries, 'file1.txt'
      assert_includes entries, 'file2.txt'

      # Test zipping a list of files
      zip_path2 = File.join(tmpdir, 'archive_files.zip')
      archive_class.create_zip(zip_path2, [file1, file2])
      assert File.exist?(zip_path2)
      entries2 = []
      Zip::File.open(zip_path2) { |zip| zip.each { |e| entries2 << e.name } }
      assert_includes entries2, 'file1.txt'
      assert_includes entries2, 'file2.txt'
    end
  end
end 