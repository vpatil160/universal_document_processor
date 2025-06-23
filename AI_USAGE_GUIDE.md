# 🤖 Universal Document Processor - AI Agent Usage Guide

## Overview

The Universal Document Processor gem includes powerful AI-powered document analysis capabilities through its built-in **Agentic AI** features. Once you've installed the gem, you can leverage AI to analyze, summarize, extract information, and interact with your documents intelligently.

## 🚀 Quick Setup

### 1. Install the Gem

```bash
gem install universal_document_processor
```

### 2. Set Up Your OpenAI API Key

```bash
# Set environment variable
export OPENAI_API_KEY="your-openai-api-key-here"
```

Or pass it directly in your code:

```ruby
options = { api_key: 'your-openai-api-key-here' }
```

### 3. Basic AI Usage

```ruby
require 'universal_document_processor'

# Basic AI analysis
result = UniversalDocumentProcessor.ai_analyze('document.pdf')
puts result
```

## 🧠 AI Features Overview

### Available AI Methods

1. **`ai_analyze`** - Comprehensive document analysis
2. **`ai_summarize`** - Generate summaries of different lengths
3. **`ai_extract_info`** - Extract specific information categories
4. **`ai_translate`** - Translate document content
5. **`ai_classify`** - Classify document type and purpose
6. **`ai_insights`** - Generate insights and recommendations
7. **`ai_action_items`** - Extract actionable items
8. **`ai_compare`** - Compare multiple documents
9. **`ai_chat`** - Interactive chat about documents

## 📝 Detailed Usage Examples

### 1. Document Analysis

#### General Analysis
```ruby
# Analyze any document comprehensively
analysis = UniversalDocumentProcessor.ai_analyze('report.pdf')
puts analysis
```

#### Specific Query Analysis
```ruby
# Ask specific questions about the document
analysis = UniversalDocumentProcessor.ai_analyze('contract.pdf', {
  query: "What are the key terms and conditions?"
})
puts analysis
```

### 2. Document Summarization

```ruby
# Short summary (2-3 sentences)
summary = UniversalDocumentProcessor.ai_summarize('document.pdf', length: :short)

# Medium summary (1-2 paragraphs) - default
summary = UniversalDocumentProcessor.ai_summarize('document.pdf', length: :medium)

# Detailed summary
summary = UniversalDocumentProcessor.ai_summarize('document.pdf', length: :long)

puts summary
```

### 3. Information Extraction

```ruby
# Extract default categories
info = UniversalDocumentProcessor.ai_extract_info('meeting_notes.pdf')

# Extract specific categories
info = UniversalDocumentProcessor.ai_extract_info('contract.pdf', [
  'parties', 'dates', 'financial_terms', 'obligations', 'deadlines'
])

puts info
```

### 4. Document Translation

```ruby
# Translate to different languages
spanish_content = UniversalDocumentProcessor.ai_translate('document.pdf', 'Spanish')
japanese_content = UniversalDocumentProcessor.ai_translate('document.pdf', 'Japanese')
french_content = UniversalDocumentProcessor.ai_translate('document.pdf', 'French')

puts spanish_content
```

### 5. Document Classification

```ruby
# Classify document type and purpose
classification = UniversalDocumentProcessor.ai_classify('unknown_document.pdf')

# Returns structured information about document type
puts classification
```

### 6. Generate Insights

```ruby
# Get AI-powered insights and recommendations
insights = UniversalDocumentProcessor.ai_insights('business_plan.pdf')

# Returns analysis of key themes, recommendations, etc.
puts insights
```

### 7. Extract Action Items

```ruby
# Extract actionable items from documents
action_items = UniversalDocumentProcessor.ai_action_items('meeting_minutes.pdf')

# Returns structured list of tasks, deadlines, assignments
puts action_items
```

### 8. Compare Documents

```ruby
# Compare multiple documents
comparison = UniversalDocumentProcessor.ai_compare([
  'version1.pdf',
  'version2.pdf',
  'version3.pdf'
], :content)

puts comparison
```

## 🎯 Advanced Usage with Document Objects

### Using Document Objects for More Control

```ruby
# Create document object for advanced operations
doc = UniversalDocumentProcessor::Document.new('complex_document.pdf')

# Use AI methods on the document object
summary = doc.ai_summarize(length: :medium)
insights = doc.ai_insights
action_items = doc.ai_action_items

# Interactive chat about the document
response = doc.ai_chat("What are the main risks mentioned in this document?")
puts response
```

### Creating and Reusing AI Agent

```ruby
# Create an AI agent with custom configuration
ai_agent = UniversalDocumentProcessor.create_ai_agent({
  model: 'gpt-4',
  temperature: 0.7,
  api_key: 'your-api-key'
})

# Process document
doc_result = UniversalDocumentProcessor.process('document.pdf')

# Use AI agent for multiple operations
summary = ai_agent.summarize_document(doc_result, length: :short)
insights = ai_agent.generate_insights(doc_result)
classification = ai_agent.classify_document(doc_result)

# Interactive chat
response = ai_agent.chat("Tell me about the financial projections", doc_result)
```

## 🛠️ Configuration Options

### AI Agent Configuration

```ruby
options = {
  api_key: 'your-openai-api-key',      # OpenAI API key
  model: 'gpt-4',                       # AI model to use
  temperature: 0.7,                     # Response creativity (0.0-1.0)
  max_history: 10,                      # Conversation history limit
  base_url: 'https://api.openai.com/v1' # API endpoint
}

# Use with any AI method
result = UniversalDocumentProcessor.ai_analyze('document.pdf', options)
```

## 💡 Use Case Examples

### 1. Legal Document Analysis

```ruby
# Analyze legal contracts
contract_analysis = UniversalDocumentProcessor.ai_analyze('contract.pdf', {
  query: "Extract all key terms, obligations, and potential risks"
})

# Extract specific legal information
legal_info = UniversalDocumentProcessor.ai_extract_info('contract.pdf', [
  'parties', 'effective_date', 'termination_clauses', 'payment_terms', 'liabilities'
])
```

### 2. Business Report Processing

```ruby
# Summarize quarterly reports
summary = UniversalDocumentProcessor.ai_summarize('q4_report.pdf', length: :medium)

# Extract key business metrics
metrics = UniversalDocumentProcessor.ai_extract_info('q4_report.pdf', [
  'revenue', 'expenses', 'profit_margins', 'growth_metrics', 'forecasts'
])

# Get strategic insights
insights = UniversalDocumentProcessor.ai_insights('q4_report.pdf')
```

### 3. Meeting Minutes Processing

```ruby
# Extract action items from meeting notes
action_items = UniversalDocumentProcessor.ai_action_items('meeting_notes.pdf')

# Summarize meeting outcomes
summary = UniversalDocumentProcessor.ai_summarize('meeting_notes.pdf', length: :short)

# Extract key decisions and follow-ups
decisions = UniversalDocumentProcessor.ai_extract_info('meeting_notes.pdf', [
  'decisions_made', 'action_items', 'deadlines', 'assigned_people'
])
```

### 4. Research Paper Analysis

```ruby
# Analyze research papers
analysis = UniversalDocumentProcessor.ai_analyze('research_paper.pdf', {
  query: "What are the main findings and methodology used?"
})

# Extract research data
research_info = UniversalDocumentProcessor.ai_extract_info('research_paper.pdf', [
  'hypothesis', 'methodology', 'results', 'conclusions', 'future_work'
])
```

## 🔄 Interactive Document Chat

```ruby
# Create document object
doc = UniversalDocumentProcessor::Document.new('document.pdf')

# Start interactive chat session
puts "Chat with your document (type 'exit' to quit):"

loop do
  print "> "
  user_input = gets.chomp
  break if user_input.downcase == 'exit'
  
  response = doc.ai_chat(user_input)
  puts "AI: #{response}\n\n"
end
```

## 📊 Batch AI Processing

```ruby
# Process multiple documents with AI
documents = ['doc1.pdf', 'doc2.docx', 'doc3.xlsx']

# Batch summarization
summaries = documents.map do |file|
  {
    file: file,
    summary: UniversalDocumentProcessor.ai_summarize(file, length: :short)
  }
end

# Batch classification
classifications = documents.map do |file|
  {
    file: file,
    classification: UniversalDocumentProcessor.ai_classify(file)
  }
end
```

## 🚨 Error Handling

```ruby
begin
  result = UniversalDocumentProcessor.ai_analyze('document.pdf')
  puts result
rescue ArgumentError => e
  puts "Configuration error: #{e.message}"
  puts "Please check your OpenAI API key"
rescue UniversalDocumentProcessor::ProcessingError => e
  puts "Processing error: #{e.message}"
rescue StandardError => e
  puts "Unexpected error: #{e.message}"
end
```

## 🎛️ Environment Variables

Set these environment variables for seamless operation:

```bash
# Required
export OPENAI_API_KEY="your-openai-api-key"

# Optional
export OPENAI_MODEL="gpt-4"
export OPENAI_TEMPERATURE="0.7"
export OPENAI_BASE_URL="https://api.openai.com/v1"
```

## 🔧 Troubleshooting

### Common Issues and Solutions

1. **Missing API Key**
   ```ruby
   # Error: ArgumentError: OpenAI API key is required
   # Solution: Set OPENAI_API_KEY environment variable or pass api_key in options
   ```

2. **API Rate Limits**
   ```ruby
   # Add delays between requests for large batch operations
   documents.each_with_index do |doc, index|
     result = UniversalDocumentProcessor.ai_analyze(doc)
     sleep(1) if index % 10 == 0  # Pause every 10 requests
   end
   ```

3. **Large Documents**
   ```ruby
   # For very large documents, consider processing in chunks
   options = { max_content_length: 10000 }
   result = UniversalDocumentProcessor.ai_analyze('large_doc.pdf', options)
   ```

## 📚 Best Practices

1. **Optimize API Usage**
   - Cache results for repeated analysis
   - Use appropriate summary lengths
   - Batch similar operations

2. **Security**
   - Store API keys securely
   - Don't log sensitive document content
   - Use environment variables for configuration

3. **Performance**
   - Process documents in parallel when possible
   - Use specific queries rather than general analysis
   - Consider document size when choosing AI operations

## 🎯 Next Steps

1. **Explore Advanced Features**: Try different AI models and temperature settings
2. **Integrate with Your Application**: Build AI-powered document workflows
3. **Customize for Your Domain**: Create domain-specific extraction categories
4. **Scale Your Usage**: Implement batch processing for large document sets

## 📞 Support

For issues with AI functionality:
1. Check your OpenAI API key and credits
2. Verify document format compatibility
3. Review error messages for specific guidance
4. Consult the main gem documentation for additional features

---

*This guide covers the AI capabilities of the Universal Document Processor gem. The AI features require an OpenAI API key and internet connection to function.* 