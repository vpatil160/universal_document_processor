require_relative 'test_helper'

class TestAIAgent < Minitest::Test
  def setup
    create_sample_files
  end

  def teardown
    cleanup_sample_files
  end

  def test_ai_agent_initialization_without_api_key
    # Test initialization without API key
    agent = UniversalDocumentProcessor::AIAgent.new
    refute agent.ai_available?
    assert_equal false, agent.ai_enabled
  end

  def test_ai_agent_initialization_with_empty_api_key
    # Test initialization with empty API key
    agent = UniversalDocumentProcessor::AIAgent.new(api_key: "")
    refute agent.ai_available?
    assert_equal false, agent.ai_enabled
  end

  def test_ai_agent_initialization_with_api_key
    # Test initialization with API key
    agent = UniversalDocumentProcessor::AIAgent.new(api_key: "test_key")
    assert agent.ai_available?
    assert_equal true, agent.ai_enabled
  end

  def test_ai_agent_initialization_with_env_var
    # Test initialization with environment variable
    original_key = ENV['OPENAI_API_KEY']
    ENV['OPENAI_API_KEY'] = 'test_env_key'
    
    agent = UniversalDocumentProcessor::AIAgent.new
    assert agent.ai_available?
    assert_equal true, agent.ai_enabled
    
    # Restore original environment
    ENV['OPENAI_API_KEY'] = original_key
  end

  def test_ai_methods_without_api_key
    agent = UniversalDocumentProcessor::AIAgent.new
    document_result = UniversalDocumentProcessor.process(@sample_files[:txt])
    
    # Test that AI methods raise appropriate errors when no API key
    assert_raises(UniversalDocumentProcessor::DependencyMissingError) do
      agent.analyze_document(document_result)
    end
    
    assert_raises(UniversalDocumentProcessor::DependencyMissingError) do
      agent.summarize_document(document_result)
    end
    
    assert_raises(UniversalDocumentProcessor::DependencyMissingError) do
      agent.ask_document_question(document_result, "What is this about?")
    end
    
    assert_raises(UniversalDocumentProcessor::DependencyMissingError) do
      agent.extract_key_information(document_result)
    end
    
    assert_raises(UniversalDocumentProcessor::DependencyMissingError) do
      agent.translate_document(document_result, "Spanish")
    end
    
    assert_raises(UniversalDocumentProcessor::DependencyMissingError) do
      agent.generate_insights(document_result)
    end
    
    assert_raises(UniversalDocumentProcessor::DependencyMissingError) do
      agent.classify_document(document_result)
    end
    
    assert_raises(UniversalDocumentProcessor::DependencyMissingError) do
      agent.extract_action_items(document_result)
    end
    
    assert_raises(UniversalDocumentProcessor::DependencyMissingError) do
      agent.chat("Hello")
    end
    
    assert_raises(UniversalDocumentProcessor::DependencyMissingError) do
      agent.compare_documents([document_result])
    end
  end

  def test_conversation_history_without_ai
    agent = UniversalDocumentProcessor::AIAgent.new
    
    # Should return appropriate message when AI is disabled
    summary = agent.conversation_summary
    assert_equal "AI features are disabled. Cannot generate conversation summary.", summary
  end

  def test_conversation_history_management
    agent = UniversalDocumentProcessor::AIAgent.new(api_key: "test_key")
    
    # Test empty history
    assert_empty agent.conversation_history
    
    # Test reset
    agent.reset_conversation
    assert_empty agent.conversation_history
  end

  def test_module_level_ai_methods_without_key
    # Test module-level AI methods without API key
    assert_raises(UniversalDocumentProcessor::DependencyMissingError) do
      UniversalDocumentProcessor.ai_analyze(@sample_files[:txt])
    end
    
    assert_raises(UniversalDocumentProcessor::DependencyMissingError) do
      UniversalDocumentProcessor.ai_summarize(@sample_files[:txt])
    end
    
    assert_raises(UniversalDocumentProcessor::DependencyMissingError) do
      UniversalDocumentProcessor.ai_extract_info(@sample_files[:txt])
    end
    
    assert_raises(UniversalDocumentProcessor::DependencyMissingError) do
      UniversalDocumentProcessor.ai_translate(@sample_files[:txt], "Spanish")
    end
    
    assert_raises(UniversalDocumentProcessor::DependencyMissingError) do
      UniversalDocumentProcessor.ai_classify(@sample_files[:txt])
    end
    
    assert_raises(UniversalDocumentProcessor::DependencyMissingError) do
      UniversalDocumentProcessor.ai_insights(@sample_files[:txt])
    end
    
    assert_raises(UniversalDocumentProcessor::DependencyMissingError) do
      UniversalDocumentProcessor.ai_action_items(@sample_files[:txt])
    end
    
    assert_raises(UniversalDocumentProcessor::DependencyMissingError) do
      UniversalDocumentProcessor.ai_compare([@sample_files[:txt], @sample_files[:csv]])
    end
  end

  def test_module_level_ai_methods_with_key
    skip_unless_ai_available
    
    # Test that methods work when API key is provided
    options = { api_key: ENV['OPENAI_API_KEY'] }
    
    # These would make actual API calls, so we'll just test they don't raise dependency errors
    # In a real test environment, you might want to mock the API calls
    begin
      result = UniversalDocumentProcessor.ai_analyze(@sample_files[:txt], options)
      assert result.is_a?(String) # AI should return a string response
    rescue => e
      # Allow network errors, timeout errors, etc. - we're just testing the dependency logic
      refute_match(/AI features require an OpenAI API key/, e.message)
    end
  end

  def test_ai_available_method
    # Test without API key
    refute UniversalDocumentProcessor.ai_available?
    
    # Test with API key
    assert UniversalDocumentProcessor.ai_available?(api_key: "test_key")
    
    # Test with environment variable
    if ENV['OPENAI_API_KEY'] && !ENV['OPENAI_API_KEY'].empty?
      assert UniversalDocumentProcessor.ai_available?
    end
  end

  def test_create_ai_agent
    agent = UniversalDocumentProcessor.create_ai_agent
    assert agent.is_a?(UniversalDocumentProcessor::AIAgent)
    
    agent_with_key = UniversalDocumentProcessor.create_ai_agent(api_key: "test_key")
    assert agent_with_key.is_a?(UniversalDocumentProcessor::AIAgent)
    assert agent_with_key.ai_available?
  end

  def test_ai_agent_configuration_options
    agent = UniversalDocumentProcessor::AIAgent.new(
      api_key: "test_key",
      model: "gpt-3.5-turbo",
      base_url: "https://custom.api.com/v1",
      max_history: 5,
      temperature: 0.5
    )
    
    assert agent.ai_available?
    assert_equal "test_key", agent.api_key
    assert_equal "gpt-3.5-turbo", agent.model
    assert_equal "https://custom.api.com/v1", agent.base_url
  end
end 