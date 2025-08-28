# RubyLLM::Template

A flexible template management system for [RubyLLM](https://github.com/crmne/ruby_llm) that allows you to organize and reuse ERB templates for AI chat interactions.

## Features

- 🎯 **Organized Templates**: Structure your prompts in folders with separate files for system, user, assistant, and schema messages
- 🔄 **ERB Templating**: Use full ERB power with context variables and Ruby logic
- ⚙️ **Configurable**: Set custom template directories per environment
- 🚀 **Rails Integration**: Seamless Rails integration with generators and automatic configuration
- 🧪 **Well Tested**: Comprehensive test suite ensuring reliability
- 📦 **Zero Dependencies**: Only depends on RubyLLM and standard Ruby libraries

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ruby_llm-template'
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
- Create `app/templates/` directory
- Generate an example template at `app/templates/extract_metadata/`

## Quick Start

### 1. Create a Template

Create a directory structure like this:

```
templates/
  extract_metadata/
    ├── system.txt.erb    # System message
    ├── user.txt.erb      # User prompt  
    ├── assistant.txt.erb # Assistant message (optional)
    └── schema.txt.erb    # JSON schema (optional)
```

### 2. Write Your Templates

**`templates/extract_metadata/system.txt.erb`**:
```erb
You are an expert document analyzer. Extract metadata from documents in a structured format.
```

**`templates/extract_metadata/user.txt.erb`**:
```erb
Please analyze this document: <%= document %>

<% if additional_context %>
Additional context: <%= additional_context %>
<% end %>
```

**`templates/extract_metadata/schema.txt.erb`**:
```erb
{
  "type": "object",
  "properties": {
    "title": {"type": "string"},
    "topics": {"type": "array", "items": {"type": "string"}},
    "summary": {"type": "string"}
  },
  "required": ["title", "topics", "summary"]
}
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
  config.template_directory = "/path/to/your/templates"
end
```

### Rails Applications

The gem automatically configures itself to use `Rails.root.join("app", "templates")`, but you can override this in `config/initializers/ruby_llm_template.rb`:

```ruby
RubyLlm::Template.configure do |config|
  config.template_directory = Rails.root.join("app", "ai_templates")
end
```

## Template Structure

Each template is a directory containing ERB files for different message roles:

- **`system.txt.erb`** - System message that sets the AI's behavior
- **`user.txt.erb`** - User message/prompt  
- **`assistant.txt.erb`** - Pre-filled assistant message (optional)
- **`schema.txt.erb`** - JSON schema for structured output (optional)

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

### Custom Schema Handling

The schema template automatically calls `with_schema()` on the chat instance with the parsed JSON:

```erb
{
  "type": "object",
  "properties": {
    "confidence": {"type": "number", "minimum": 0, "maximum": 1},
    "results": {
      "type": "array",
      "items": {
        "type": "object", 
        "properties": {
          "item": {"type": "string"},
          "score": {"type": "number"}
        }
      }
    }
  }
}
```

## Error Handling

The gem provides clear error messages for common issues:

```ruby
begin
  RubyLLM.chat.with_template(:nonexistent).complete
rescue RubyLlm::Template::Error => e
  puts e.message # "Template 'nonexistent' not found in /path/to/templates"
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
