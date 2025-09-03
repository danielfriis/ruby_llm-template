# RubyLLM::Template

[![Gem Version](https://badge.fury.io/rb/ruby_llm-template.svg)](https://rubygems.org/gems/ruby_llm-template)
[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/danielfriis/ruby_llm-template/blob/main/LICENSE.txt)
[![CI](https://github.com/danielfriis/ruby_llm-template/actions/workflows/ci.yml/badge.svg)](https://github.com/danielfriis/ruby_llm-template/actions/workflows/ci.yml)

A flexible template management system for [RubyLLM](https://github.com/crmne/ruby_llm) that allows you to organize and reuse ERB templates.

```ruby
RubyLLM.chat.with_template(:extract_metadata, document: @document).complete

# ----------------------------------
# Retrieves the following files:
# ----------------------------------
# prompts/
#   extract_metadata/
#     ├── system.txt.erb    # System message
#     ├── user.txt.erb      # User prompt  
#     ├── assistant.txt.erb # Assistant message (optional)
#     └── schema.rb         # RubyLLM::Schema definition (optional)

```

## Features

- 🎯 **Organized Templates**: Structure your prompts in folders with separate files for system, user, assistant, and schema messages
- 🔄 **ERB Templating**: Use full ERB power with context variables and Ruby logic
- ⚙️ **Configurable**: Set custom template directories per environment
- 🚀 **Rails Integration**: Seamless Rails integration with generators and automatic configuration
- 🧪 **Well Tested**: Comprehensive test suite ensuring reliability
- 📦 **Minimal Dependencies**: Only depends on RubyLLM and standard Ruby libraries

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ruby_llm'
gem 'ruby_llm-template'
gem 'ruby_llm-schema'  # Optional for schema.rb support
```

And then execute:

```bash
bundle install
```

### Rails Setup

If you're using Rails, run the generator to set up the template system:

```bash
rails generate ruby_llm_template:install
```

This will:
- Create `config/initializers/ruby_llm_template.rb`
- Create `app/prompts/` directory
- Generate an example template at `app/prompts/extract_metadata/`

## Quick Start

### 1. Create a Template

Create a directory structure like this:

```
prompts/
  extract_metadata/
    ├── system.txt.erb    # System message
    ├── user.txt.erb      # User prompt  
    ├── assistant.txt.erb # Assistant message (optional)
    └── schema.rb         # RubyLLM::Schema definition (optional)
```

### 2. Write Your Templates

**`prompts/extract_metadata/system.txt.erb`**:
```erb
You are an expert document analyzer. Extract metadata from documents in a structured format.
```

**`prompts/extract_metadata/user.txt.erb`**:
```erb
Please analyze this document: <%= document %>

<% if additional_context %>
Additional context: <%= additional_context %>
<% end %>
```

**`prompts/extract_metadata/schema.rb`**:
```ruby
# Using RubyLLM::Schema DSL for clean, type-safe schemas
RubyLLM::Schema.create do
  string :title, description: "Document title"
  array :topics, description: "Main topics" do
    string
  end
  string :summary, description: "Brief summary"
  
  # Optional fields with validation
  number :confidence, required: false, minimum: 0, maximum: 1
  
  # Nested objects
  object :metadata, required: false do
    string :author
    string :date, format: "date"
  end
end
```

### 3. Use the Template

```ruby
# Basic usage
RubyLLM.chat.with_template(:extract_metadata, document: @document).complete

# With context variables
RubyLLM.chat.with_template(:extract_metadata, 
  document: @document,
  additional_context: "Focus on technical details"
).complete

# Chaining with other RubyLLM methods
RubyLLM.chat
  .with_template(:extract_metadata, document: @document)
  .with_model("gpt-4")
  .complete
```

## Configuration

### Non-Rails Applications

```ruby
RubyLlm::Template.configure do |config|
  config.template_directory = "/path/to/your/prompts"
end
```

### Rails Applications

The gem automatically configures itself to use `Rails.root.join("app", "prompts")`, but you can override this in `config/initializers/ruby_llm_template.rb`:

```ruby
RubyLlm::Template.configure do |config|
  config.template_directory = Rails.root.join("app", "ai_prompts")
end
```

## Template Structure

Each template is a directory containing ERB files for different message roles:

- **`system.txt.erb`** - System message that sets the AI's behavior
- **`user.txt.erb`** - User message/prompt  
- **`assistant.txt.erb`** - Pre-filled assistant message (optional)
- **`schema.rb`** - RubyLLM::Schema definition for structured output (optional)

Templates are processed in order: system → user → assistant → schema

## ERB Context

All context variables passed to `with_template` are available in your ERB templates:

```erb
Hello <%= name %>!

<% if urgent %>
🚨 URGENT: <%= message %>
<% else %>
📋 Regular: <%= message %>
<% end %>

Processing <%= documents.length %> documents:
<% documents.each_with_index do |doc, i| %>
  <%= i + 1 %>. <%= doc.title %>
<% end %>
```

## Advanced Usage

### Complex Templates

```ruby
# Template with conditional logic and loops
RubyLLM.chat.with_template(:analyze_reports,
  reports: @reports,
  priority: "high",
  include_charts: true,
  deadline: 1.week.from_now
).complete
```

### Multiple Template Calls

```ruby
chat = RubyLLM.chat
  .with_template(:initialize_session, user: current_user)
  .with_template(:load_context, project: @project)
  
# Add more messages dynamically
chat.ask("What should we focus on first?")
```

### Schema Definition with RubyLLM::Schema

The gem integrates with [RubyLLM::Schema](https://github.com/danielfriis/ruby_llm-schema) to provide a clean Ruby DSL for defining JSON schemas. Use `schema.rb` files instead of JSON:

```ruby
# prompts/analyze_results/schema.rb
RubyLLM::Schema.create do
  number :confidence, minimum: 0, maximum: 1, description: "Analysis confidence"
  
  array :results, description: "Analysis results" do
    object do
      string :item, description: "Result item"
      number :score, minimum: 0, maximum: 100, description: "Item score"
      
      # Context variables are available
      string :category, enum: categories if defined?(categories)
    end
  end
  
  # Optional nested structures
  object :metadata, required: false do
    string :model_version
    string :timestamp, format: "date-time"
  end
end
```

**Benefits of `schema.rb`:**
- 🎯 **Type-safe**: Ruby DSL with built-in validation
- 🔄 **Dynamic**: Access template context variables for conditional schemas
- 📝 **Readable**: Clean, self-documenting Ruby syntax vs JSON
- 🔧 **Flexible**: Generate schemas based on runtime conditions
- 🚀 **No JSON**: Eliminate error-prone JSON string manipulation

**Schema-Only Approach**: The gem exclusively supports `schema.rb` files with RubyLLM::Schema. If you have a `schema.rb` file but the gem isn't installed, you'll get a clear error message.

## Error Handling

The gem provides clear error messages for common issues:

```ruby
begin
  RubyLLM.chat.with_template(:extract_metadata).complete
rescue RubyLlm::Template::Error => e
  puts e.message 
  # "Template 'extract_metadata' not found in /path/to/prompts"
  # "Schema file 'extract_metadata/schema.rb' found but RubyLLM::Schema gem is not installed"
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To run the test suite:

```bash
bundle exec rspec
```

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/danielfriis/ruby_llm-template.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
