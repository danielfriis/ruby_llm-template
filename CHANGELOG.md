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
- Rails integration with automatic configuration and generator
- Comprehensive test suite with 28 test cases
- Error handling with descriptive messages
- Documentation and examples

### Features
- **Template Organization**: Structure prompts in folders with separate ERB files for each message role
- **ERB Templating**: Full ERB support with context variables and Ruby logic
- **Rails Integration**: Seamless Rails integration with generators and automatic configuration
- **Configurable**: Set custom template directories per environment
- **Schema Support**: Automatic JSON schema parsing and application
- **Error Handling**: Clear error messages for common issues
- **Zero Dependencies**: Only depends on RubyLLM and standard Ruby libraries

### Usage
```ruby
# Basic usage
RubyLLM.chat.with_template(:extract_metadata, document: @document).complete

# With context variables
RubyLLM.chat.with_template(:extract_metadata, 
  document: @document,
  additional_context: "Focus on technical details"
).complete
```

### Rails Setup
```bash
rails generate ruby_llm_template:install
```
