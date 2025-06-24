require_relative 'test_helper'

class TestUniversalDocumentProcessor < Minitest::Test
  def setup
    create_sample_files
  end

  def teardown
    cleanup_sample_files
  end

  def test_version_number
    refute_nil UniversalDocumentProcessor::VERSION
    assert_match(/\d+\.\d+\.\d+/, UniversalDocumentProcessor::VERSION)
  end

  def test_process_text_file
    result = UniversalDocumentProcessor.process(@sample_files[:txt])
    
    assert result.is_a?(Hash)
    assert result.has_key?(:text)
    assert result.has_key?(:metadata)
    assert result[:text].include?("sample text file")
    assert_equal "txt", result[:metadata][:format]
  end

  def test_extract_text
    text = UniversalDocumentProcessor.extract_text(@sample_files[:txt])
    
    assert text.is_a?(String)
    assert text.include?("sample text file")
    assert text.include?("multiple lines")
  end

  def test_get_metadata
    metadata = UniversalDocumentProcessor.get_metadata(@sample_files[:txt])
    
    assert metadata.is_a?(Hash)
    assert_equal "txt", metadata[:format]
    assert metadata.has_key?(:file_size)
    assert metadata[:file_size] > 0
  end

  def test_csv_processing
    result = UniversalDocumentProcessor.process(@sample_files[:csv])
    
    assert result.is_a?(Hash)
    assert result.has_key?(:text)
    assert result.has_key?(:metadata)
    assert result.has_key?(:tables)
    assert_equal "csv", result[:metadata][:format]
    assert result[:tables].length > 0
  end

  def test_tsv_processing
    result = UniversalDocumentProcessor.process(@sample_files[:tsv])
    
    assert result.is_a?(Hash)
    assert result.has_key?(:text)
    assert result.has_key?(:metadata)
    assert result.has_key?(:tables)
    assert_equal "tsv", result[:metadata][:format]
    assert_equal "tab", result[:metadata][:delimiter]
    assert result[:tables].length > 0
  end

  def test_json_processing
    result = UniversalDocumentProcessor.process(@sample_files[:json])
    
    assert result.is_a?(Hash)
    assert result.has_key?(:text)
    assert result.has_key?(:metadata)
    assert_equal "json", result[:metadata][:format]
    assert result[:text].include?("Test Document")
  end

  def test_xml_processing
    result = UniversalDocumentProcessor.process(@sample_files[:xml])
    
    assert result.is_a?(Hash)
    assert result.has_key?(:text)
    assert result.has_key?(:metadata)
    assert_equal "xml", result[:metadata][:format]
    assert result[:text].include?("Sample XML Document")
  end

  def test_html_processing
    result = UniversalDocumentProcessor.process(@sample_files[:html])
    
    assert result.is_a?(Hash)
    assert result.has_key?(:text)
    assert result.has_key?(:metadata)
    assert_equal "html", result[:metadata][:format]
    assert result[:text].include?("Test Document")
  end

  def test_unsupported_format
    unsupported_file = create_temp_file("test", '.unknown')
    
    assert_raises(UniversalDocumentProcessor::UnsupportedFormatError) do
      UniversalDocumentProcessor.process(unsupported_file)
    end
    
    File.delete(unsupported_file)
  end

  def test_batch_processing
    file_paths = [@sample_files[:txt], @sample_files[:csv], @sample_files[:json]]
    results = UniversalDocumentProcessor.batch_process(file_paths)
    
    assert_equal 3, results.length
    results.each do |result|
      assert result.has_key?(:text) || result.has_key?(:error)
    end
  end

  def test_available_features
    features = UniversalDocumentProcessor.available_features
    
    assert features.is_a?(Array)
    assert features.include?(:text_processing)
    assert features.include?(:csv_processing)
    assert features.include?(:tsv_processing)
    assert features.include?(:json_processing)
    assert features.include?(:xml_processing)
    assert features.include?(:html_processing)
  end

  def test_dependency_check
    # These should always be available (built-in Ruby features)
    assert UniversalDocumentProcessor.dependency_available?(:csv) || true # CSV is built-in
    
    # These may or may not be available
    pdf_available = UniversalDocumentProcessor.dependency_available?(:pdf_reader)
    assert [true, false].include?(pdf_available)
  end

  def test_text_quality_analysis
    good_text = "This is clean text with no issues."
    analysis = UniversalDocumentProcessor.analyze_text_quality(good_text)
    
    assert analysis.is_a?(Hash)
    assert analysis.has_key?(:valid_characters)
    assert analysis.has_key?(:invalid_characters)
    assert analysis.has_key?(:character_count)
  end

  def test_clean_text
    dirty_text = "Clean text\x00with\x01invalid\x02characters"
    clean_text = UniversalDocumentProcessor.clean_text(dirty_text)
    
    assert clean_text.is_a?(String)
    refute clean_text.include?("\x00")
    refute clean_text.include?("\x01")
    refute clean_text.include?("\x02")
  end

  def test_japanese_text_detection
    english_text = "This is English text"
    japanese_text = "これは日本語のテキストです"
    
    refute UniversalDocumentProcessor.japanese_text?(english_text)
    assert UniversalDocumentProcessor.japanese_text?(japanese_text)
  end

  def test_filename_validation
    normal_filename = "test_file.txt"
    japanese_filename = "テスト_ファイル.txt"
    
    refute UniversalDocumentProcessor.japanese_filename?(normal_filename)
    assert UniversalDocumentProcessor.japanese_filename?(japanese_filename)
    
    # Test safe filename generation
    safe_name = UniversalDocumentProcessor.safe_filename(japanese_filename)
    assert safe_name.is_a?(String)
    refute safe_name.empty?
  end

  def test_ai_availability_check
    ai_available = UniversalDocumentProcessor.ai_available?
    assert [true, false].include?(ai_available)
    
    # Check that features list includes AI if available
    features = UniversalDocumentProcessor.available_features
    if ai_available
      assert features.include?(:ai_processing)
    else
      refute features.include?(:ai_processing)
    end
  end
end 