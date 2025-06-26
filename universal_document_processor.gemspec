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

  spec.required_ruby_version = ">= 2.2.2"

  # Core dependencies - essential ones
  spec.add_dependency "activesupport", ">= 5.0", "< 9.0"
  spec.add_dependency "marcel", "~> 1.0"     # MIME type detection
  spec.add_dependency "nokogiri", "~> 1.13"  # XML/HTML parsing
  spec.add_dependency "rubyzip", "~> 2.3"    # ZIP archives
  spec.add_dependency "rexml", "~> 3.2"      # XML parsing for Excel files
  
  # Optional dependencies for enhanced functionality
  # These are loaded conditionally and gracefully degrade if not available
  spec.metadata["optional_dependencies"] = "pdf-reader ~> 2.0, prawn ~> 2.4, docx ~> 0.8, roo ~> 2.8, mini_magick ~> 4.11, yomu ~> 0.2"
  
  # Development dependencies
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "minitest-reporters", "~> 1.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rubocop", "~> 1.50"
  spec.add_development_dependency "yard", "~> 0.9"
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "simplecov", "~> 0.22"
end 