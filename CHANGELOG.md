# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-01-28

### Added
- Initial release of RubyLLM::Template
- Template management system for RubyLLM with ERB support
- Configuration system for template directories
- Support for system, user, assistant, and schema message templates
- **RubyLLM::Schema Integration**: Support for `schema.rb` files using the RubyLLM::Schema DSL
- Rails integration with automatic configuration and generator
- Comprehensive test suite with 37 test cases
- Error handling with descriptive messages
- Documentation and examples

### Features
- **Template Organization**: Structure prompts in folders with separate ERB files for each message role
- **ERB Templating**: Full ERB support with context variables and Ruby logic
- **Schema Definition**: Use `schema.rb` files with RubyLLM::Schema DSL for type-safe, dynamic schemas
- **Rails Integration**: Seamless Rails integration with generators and automatic configuration
- **Configurable**: Set custom template directories per environment
- **Schema Support**: Automatic schema loading and application with fallback to JSON
- **Error Handling**: Clear error messages for common issues
- **Smart Dependencies**: Optional RubyLLM::Schema dependency with graceful fallbacks

### Schema Features
- **Ruby DSL**: Use RubyLLM::Schema for clean, type-safe schema definitions
- **Context Variables**: Access template context variables within schema.rb files
- **Dynamic Schemas**: Generate schemas based on runtime conditions
- **Schema-Only Approach**: Exclusively supports schema.rb files with clear error messages
- **No JSON Fallback**: Eliminates error-prone JSON string manipulation

### Usage
```ruby
# Basic usage with schema.rb
RubyLLM.chat.with_template(:extract_metadata, document: @document).complete

# Context variables available in both ERB and schema.rb
RubyLLM.chat.with_template(:extract_metadata, 
  document: @document,
  categories: ["finance", "technology"],
  max_items: 10
).complete
```

### Template Structure
```
prompts/extract_metadata/
├── system.txt.erb    # System message
├── user.txt.erb      # User prompt with ERB
├── assistant.txt.erb # Optional assistant message
└── schema.rb         # RubyLLM::Schema definition
```

### Rails Setup
```bash
rails generate ruby_llm_template:install
```
