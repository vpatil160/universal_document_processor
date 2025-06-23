require_relative "lib/universal_document_processor/version"

Gem::Specification.new do |spec|
  spec.name          = "universal_document_processor"
  spec.version       = UniversalDocumentProcessor::VERSION
  spec.authors       = ["Vikas Patil"]
  spec.email         = ["vikas.v.patil1696@gmail.com"]

  spec.summary       = "Universal document processor with AI capabilities for all file formats"
  spec.description   = "A comprehensive Ruby gem that handles document processing, text extraction, and AI-powered analysis for PDF, Word, Excel, PowerPoint, images, archives, and more with a unified API. Includes agentic AI features for document analysis, summarization, and intelligent extraction."
  spec.homepage      = "https://github.com/vpatil160/universal_document_processor"
  spec.license       = "MIT"

  spec.metadata = {
    "homepage_uri"      => spec.homepage,
    "source_code_uri"   => "https://github.com/vpatil160/universal_document_processor",
    "bug_tracker_uri"   => "https://github.com/vpatil160/universal_document_processor/issues",
    "changelog_uri"     => "https://github.com/vpatil160/universal_document_processor/blob/main/CHANGELOG.md",
    "documentation_uri" => "https://github.com/vpatil160/universal_document_processor/blob/main/README.md",
    "funding_uri"       => "https://github.com/sponsors/vpatil160",
    "rubygems_mfa_required" => "true"
  }

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.7.0"

  # Core dependencies - essential ones
  spec.add_dependency "activesupport", "~> 7.0"
  spec.add_dependency "marcel", "~> 1.0"     # MIME type detection
  spec.add_dependency "nokogiri", "~> 1.13"  # XML/HTML parsing
  spec.add_dependency "rubyzip", "~> 2.3"    # ZIP archives
  
  # Optional dependencies for enhanced functionality
  # Uncomment these based on what features you want to include by default
  # spec.add_dependency "pdf-reader", "~> 2.0"    # PDF processing
  # spec.add_dependency "prawn", "~> 2.4"         # PDF generation
  # spec.add_dependency "docx", "~> 0.8"          # Word documents
  # spec.add_dependency "roo", "~> 2.8"           # Excel/Spreadsheets
  # spec.add_dependency "mini_magick", "~> 4.11"  # Image processing
  # spec.add_dependency "yomu", "~> 0.2"          # Universal text extraction fallback
  
  # Development dependencies
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rubocop", "~> 1.50"
  spec.add_development_dependency "yard", "~> 0.9"
  spec.add_development_dependency "bundler", "~> 2.0"
end 