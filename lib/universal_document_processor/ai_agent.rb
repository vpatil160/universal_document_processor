require 'net/http'
require 'json'
require 'uri'

module UniversalDocumentProcessor
  class AIAgent
    attr_reader :api_key, :model, :base_url, :conversation_history, :ai_enabled

    def initialize(options = {})
      @api_key = options[:api_key] || ENV['OPENAI_API_KEY']
      @model = options[:model] || 'gpt-4'
      @base_url = options[:base_url] || 'https://api.openai.com/v1'
      @conversation_history = []
      @max_history = options[:max_history] || 10
      @temperature = options[:temperature] || 0.7
      @ai_enabled = false
      
      validate_configuration
    end

    # Main document analysis with AI
    def analyze_document(document_result, query = nil)
      ensure_ai_available!
      
      context = build_document_context(document_result)
      
      if query
        # Specific query about the document
        analyze_with_query(context, query)
      else
        # General document analysis
        perform_general_analysis(context)
      end
    end

    def analyze_with_query(context, query)
      prompt = build_question_prompt(context, query)
      response = call_openai_api(prompt)
      add_to_history("Analyze document: #{query}", response)
      response
    end

    def perform_general_analysis(context)
      prompt = "You are an AI document analyst. Provide a comprehensive analysis of this document:

Document: #{context[:filename]} (#{context[:content_type]})
Size: #{format_file_size(context[:file_size])}
Images: #{context[:images_count]}
Tables: #{context[:tables_count]}
#{context[:japanese_filename] ? "Japanese filename: Yes" : ""}

Content:
#{truncate_content(context[:text_content], 3500)}

Please provide:
1. Document summary
2. Key topics and themes
3. Document structure analysis
4. Content quality assessment
5. Recommendations for use"

      response = call_openai_api(prompt)
      add_to_history("General document analysis", response)
      response
    end

    # Ask specific questions about a document
    def ask_document_question(document_result, question)
      ensure_ai_available!
      
      context = build_document_context(document_result)
      
      prompt = build_question_prompt(context, question)
      response = call_openai_api(prompt)
      
      add_to_history(question, response)
      response
    end

    # Summarize document content
    def summarize_document(document_result, length: :medium)
      ensure_ai_available!
      
      context = build_document_context(document_result)
      
      length_instruction = case length
      when :short then "in 2-3 sentences"
      when :medium then "in 1-2 paragraphs"
      when :long then "in detail with key points"
      else "concisely"
      end
      
      prompt = build_summary_prompt(context, length_instruction)
      response = call_openai_api(prompt)
      
      add_to_history("Summarize document #{length_instruction}", response)
      response
    end

    # Extract key information from document
    def extract_key_information(document_result, categories = nil)
      ensure_ai_available!
      
      context = build_document_context(document_result)
      categories ||= ['key_facts', 'important_dates', 'names', 'locations', 'numbers']
      
      prompt = build_extraction_prompt(context, categories)
      response = call_openai_api(prompt)
      
      add_to_history("Extract key information: #{categories.join(', ')}", response)
      parse_extraction_response(response)
    end

    # Translate document content
    def translate_document(document_result, target_language)
      ensure_ai_available!
      
      context = build_document_context(document_result)
      
      prompt = build_translation_prompt(context, target_language)
      response = call_openai_api(prompt)
      
      add_to_history("Translate to #{target_language}", response)
      response
    end

    # Generate document insights and recommendations
    def generate_insights(document_result)
      ensure_ai_available!
      
      context = build_document_context(document_result)
      
      prompt = build_insights_prompt(context)
      response = call_openai_api(prompt)
      
      add_to_history("Generate insights", response)
      parse_insights_response(response)
    end

    # Compare multiple documents
    def compare_documents(document_results, comparison_type = :content)
      ensure_ai_available!
      
      contexts = document_results.map { |doc| build_document_context(doc) }
      
      prompt = build_comparison_prompt(contexts, comparison_type)
      response = call_openai_api(prompt)
      
      add_to_history("Compare documents (#{comparison_type})", response)
      response
    end

    # Classify document type and purpose
    def classify_document(document_result)
      ensure_ai_available!
      
      context = build_document_context(document_result)
      
      prompt = build_classification_prompt(context)
      response = call_openai_api(prompt)
      
      add_to_history("Classify document", response)
      parse_classification_response(response)
    end

    # Generate action items from document
    def extract_action_items(document_result)
      ensure_ai_available!
      
      context = build_document_context(document_result)
      
      prompt = build_action_items_prompt(context)
      response = call_openai_api(prompt)
      
      add_to_history("Extract action items", response)
      parse_action_items_response(response)
    end

    # Chat about the document
    def chat(message, document_result = nil)
      ensure_ai_available!
      
      if document_result
        context = build_document_context(document_result)
        prompt = build_chat_prompt(context, message)
      else
        prompt = build_general_chat_prompt(message)
      end
      
      response = call_openai_api(prompt)
      add_to_history(message, response)
      response
    end

    # Reset conversation history
    def reset_conversation
      @conversation_history.clear
    end

    # Get conversation summary
    def conversation_summary
      return "No conversation history" if @conversation_history.empty?
      
      unless @ai_enabled
        return "AI features are disabled. Cannot generate conversation summary."
      end
      
      history_text = @conversation_history.map do |entry|
        "Q: #{entry[:question]}\nA: #{entry[:answer]}"
      end.join("\n\n")
      
      prompt = "Summarize this conversation:\n\n#{history_text}"
      call_openai_api(prompt)
    end

    # Check if AI features are available
    def ai_available?
      @ai_enabled
    end

    private

    def validate_configuration
      if @api_key && !@api_key.empty?
        @ai_enabled = true
      else
        @ai_enabled = false
        warn "Warning: OpenAI API key not provided. AI features will be disabled. Set OPENAI_API_KEY environment variable or pass api_key option to enable AI features."
      end
    end

    # Ensure AI is available before making API calls
    def ensure_ai_available!
      unless @ai_enabled
        raise DependencyMissingError, "AI features are not available. Please provide an OpenAI API key to use AI functionality."
      end
    end

    def build_document_context(document_result)
      context = {
        filename: document_result[:file_path] ? File.basename(document_result[:file_path]) : "Unknown",
        content_type: document_result[:content_type] || "Unknown",
        file_size: document_result[:file_size] || 0,
        text_content: document_result[:text_content] || "",
        metadata: document_result[:metadata] || {},
        images_count: document_result[:images]&.length || 0,
        tables_count: document_result[:tables]&.length || 0,
        filename_info: document_result[:filename_info] || {}
      }
      
      # Add Japanese-specific information if available
      if context[:filename_info][:contains_japanese]
        context[:japanese_filename] = true
        context[:japanese_parts] = context[:filename_info][:japanese_parts]
      end
      
      context
    end

    def build_question_prompt(context, question)
      "You are an AI assistant analyzing a document. Here's the document information:

Filename: #{context[:filename]}
Type: #{context[:content_type]}
Size: #{format_file_size(context[:file_size])}
Images: #{context[:images_count]}
Tables: #{context[:tables_count]}
#{context[:japanese_filename] ? "Japanese filename: Yes" : ""}

Content:
#{truncate_content(context[:text_content], 3000)}

Question: #{question}

Please provide a detailed and accurate answer based on the document content."
    end

    def build_summary_prompt(context, length_instruction)
      "You are an AI assistant. Please summarize the following document #{length_instruction}:

Document: #{context[:filename]} (#{context[:content_type]})
Content:
#{truncate_content(context[:text_content], 4000)}

Provide a clear and informative summary."
    end

    def build_extraction_prompt(context, categories)
      "You are an AI assistant. Extract the following information from this document:

Categories to extract: #{categories.join(', ')}

Document: #{context[:filename]}
Content:
#{truncate_content(context[:text_content], 3500)}

Please provide the extracted information in a structured format with clear categories."
    end

    def build_translation_prompt(context, target_language)
      "You are a professional translator. Translate the following document content to #{target_language}:

Document: #{context[:filename]}
Original content:
#{truncate_content(context[:text_content], 3000)}

Please provide an accurate and natural translation."
    end

    def build_insights_prompt(context)
      "You are an AI analyst. Analyze this document and provide insights, key themes, and recommendations:

Document: #{context[:filename]} (#{context[:content_type]})
Content:
#{truncate_content(context[:text_content], 3500)}

Please provide:
1. Key themes and topics
2. Important insights
3. Potential concerns or issues
4. Recommendations or next steps
5. Overall assessment"
    end

    def build_comparison_prompt(contexts, comparison_type)
      comparison_content = contexts.map.with_index do |context, index|
        "Document #{index + 1}: #{context[:filename]}
Content: #{truncate_content(context[:text_content], 1500)}"
      end.join("\n\n---\n\n")

      "You are an AI analyst. Compare these documents focusing on #{comparison_type}:

#{comparison_content}

Please provide a detailed comparison highlighting similarities, differences, and key insights."
    end

    def build_classification_prompt(context)
      "You are a document classification expert. Classify this document:

Document: #{context[:filename]} (#{context[:content_type]})
Content:
#{truncate_content(context[:text_content], 2000)}

Please classify this document by:
1. Document type (e.g., report, contract, manual, etc.)
2. Industry/domain
3. Purpose/intent
4. Urgency level
5. Target audience

Provide your classification with reasoning."
    end

    def build_action_items_prompt(context)
      "You are an AI assistant specialized in extracting actionable items. Analyze this document:

Document: #{context[:filename]}
Content:
#{truncate_content(context[:text_content], 3000)}

Extract and list:
1. Action items or tasks mentioned
2. Deadlines or due dates
3. Responsible parties (if mentioned)
4. Priority levels
5. Dependencies

Format as a clear, actionable list."
    end

    def build_chat_prompt(context, message)
      history_context = @conversation_history.last(5).map do |entry|
        "Previous Q: #{entry[:question]}\nPrevious A: #{entry[:answer]}"
      end.join("\n")

      "You are an AI assistant discussing a document with a user.

Document context:
Filename: #{context[:filename]}
Type: #{context[:content_type]}
Content: #{truncate_content(context[:text_content], 2000)}

#{history_context.empty? ? "" : "Recent conversation:\n#{history_context}\n"}

User message: #{message}

Please respond helpfully based on the document and our conversation."
    end

    def build_general_chat_prompt(message)
      history_context = @conversation_history.last(5).map do |entry|
        "Q: #{entry[:question]}\nA: #{entry[:answer]}"
      end.join("\n")

      "You are an AI assistant helping with document processing tasks.

#{history_context.empty? ? "" : "Recent conversation:\n#{history_context}\n"}

User message: #{message}

Please respond helpfully."
    end

    def call_openai_api(prompt)
      uri = URI("#{@base_url}/chat/completions")
      
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 60
      
      request = Net::HTTP::Post.new(uri)
      request['Content-Type'] = 'application/json'
      request['Authorization'] = "Bearer #{@api_key}"
      
      request.body = {
        model: @model,
        messages: [
          {
            role: "system",
            content: "You are an intelligent document processing assistant with expertise in analyzing, summarizing, and extracting information from various document types. You support multiple languages including Japanese."
          },
          {
            role: "user", 
            content: prompt
          }
        ],
        temperature: @temperature,
        max_tokens: 2000
      }.to_json
      
      response = http.request(request)
      
      if response.code.to_i == 200
        result = JSON.parse(response.body)
        result.dig('choices', 0, 'message', 'content') || "No response generated"
      else
        error_body = JSON.parse(response.body) rescue response.body
        raise "OpenAI API Error (#{response.code}): #{error_body}"
      end
    end

    def add_to_history(question, answer)
      @conversation_history << {
        question: question,
        answer: answer,
        timestamp: Time.now
      }
      
      # Keep only the most recent conversations
      @conversation_history = @conversation_history.last(@max_history) if @conversation_history.length > @max_history
    end

    def truncate_content(content, max_length)
      return "" unless content.is_a?(String)
      
      if content.length > max_length
        "#{content[0...max_length]}...\n\n[Content truncated for analysis]"
      else
        content
      end
    end

    def format_file_size(bytes)
      return "0 B" if bytes == 0
      
      units = ['B', 'KB', 'MB', 'GB']
      size = bytes.to_f
      unit_index = 0
      
      while size >= 1024 && unit_index < units.length - 1
        size /= 1024
        unit_index += 1
      end
      
      "#{size.round(2)} #{units[unit_index]}"
    end

    def parse_extraction_response(response)
      # Try to parse structured response
      begin
        # Look for JSON-like structure in response
        if response.include?('{') && response.include?('}')
          # Extract JSON part
          json_match = response.match(/\{.*\}/m)
          if json_match
            return JSON.parse(json_match[0])
          end
        end
      rescue JSON::ParserError
        # Fall back to plain text response
      end
      
      response
    end

    def parse_insights_response(response)
      {
        raw_response: response,
        timestamp: Time.now,
        insights: extract_numbered_list(response)
      }
    end

    def parse_classification_response(response)
      {
        raw_response: response,
        classification: response,
        timestamp: Time.now
      }
    end

    def parse_action_items_response(response)
      {
        raw_response: response,
        action_items: extract_numbered_list(response),
        timestamp: Time.now
      }
    end

    def extract_numbered_list(text)
      # Extract numbered or bulleted lists from text
      items = []
      text.split("\n").each do |line|
        if line.match(/^\s*[\d\-\*\•]\s*(.+)/)
          items << line.strip
        end
      end
      items
    end
  end
end 