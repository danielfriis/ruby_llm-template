#!/usr/bin/env ruby
# frozen_string_literal: true

# Example of using RubyLLM::Template
# This file demonstrates basic usage without actually calling RubyLLM APIs

require_relative "../lib/ruby_llm/template"

# Configure template directory
RubyLlm::Template.configure do |config|
  config.template_directory = File.join(__dir__, "templates")
end

# Create example templates directory
templates_dir = File.join(__dir__, "templates", "extract_metadata")
FileUtils.mkdir_p(templates_dir)

# Create example template files
File.write(File.join(templates_dir, "system.txt.erb"), <<~ERB)
  You are an expert document analyzer. Your task is to extract metadata from the provided document.
  
  Please analyze the document carefully and extract relevant information such as:
  - Document type
  - Key topics  
  - Important dates
  - Main entities mentioned
  
  Provide your analysis in a structured format.
ERB

File.write(File.join(templates_dir, "user.txt.erb"), <<~ERB)
  Please analyze the following document and extract its metadata:
  
  Document: <%= document %>
  
  <% if additional_context %>
  Additional context: <%= additional_context %>
  <% end %>
  
  Focus areas: <%= focus_areas.join(", ") if defined?(focus_areas) && focus_areas.any? %>
ERB

File.write(File.join(templates_dir, "schema.txt.erb"), <<~ERB)
  {
    "type": "object",
    "properties": {
      "document_type": {
        "type": "string",
        "description": "The type of document (e.g., report, article, email)"
      },
      "key_topics": {
        "type": "array",
        "items": {
          "type": "string"
        },
        "description": "Main topics discussed in the document"
      },
      "important_dates": {
        "type": "array",
        "items": {
          "type": "string",
          "format": "date"
        },
        "description": "Significant dates mentioned in the document"
      },
      "entities": {
        "type": "array",
        "items": {
          "type": "object",
          "properties": {
            "name": {
              "type": "string"
            },
            "type": {
              "type": "string",
              "enum": ["person", "organization", "location", "other"]
            }
          }
        },
        "description": "Named entities found in the document"
      }
    },
    "required": ["document_type", "key_topics"]
  }
ERB

puts "🎯 RubyLLM::Template Example"
puts "=" * 40

# Mock chat object that demonstrates the extension
class MockChat
  include RubyLlm::Template::ChatExtension
  
  def initialize
    @messages = []
    @schema = nil
  end
  
  def add_message(role:, content:)
    @messages << {role: role, content: content}
    puts "📝 Added #{role} message: #{content[0..100]}#{'...' if content.length > 100}"
  end
  
  def with_schema(schema)
    @schema = schema
    puts "📋 Schema applied with #{schema.keys.length} properties"
    self
  end
  
  def complete
    puts "\n🤖 Chat would now be sent to AI with:"
    puts "   - #{@messages.length} messages"
    puts "   - Schema: #{@schema ? 'Yes' : 'No'}"
    puts "\n💬 Messages:"
    @messages.each_with_index do |msg, i|
      puts "   #{i + 1}. [#{msg[:role].upcase}] #{msg[:content][0..80]}#{'...' if msg[:content].length > 80}"
    end
    self
  end
end

# Simulate the usage
begin
  chat = MockChat.new
  
  # This demonstrates the desired API:
  # RubyLLM.chat.with_template(:extract_metadata, context).complete
  chat.with_template(:extract_metadata, 
    document: "Q3 Financial Report: Revenue increased 15% to $2.3M. Key challenges include supply chain delays affecting Q4 projections.",
    additional_context: "Focus on financial metrics and future outlook",
    focus_areas: ["revenue", "challenges", "projections"]
  ).complete
  
rescue RubyLlm::Template::Error => e
  puts "❌ Error: #{e.message}"
end

puts "\n✅ Example completed successfully!"
puts "\nTo use with real RubyLLM:"
puts "  RubyLLM.chat.with_template(:extract_metadata, document: @document).complete"

# Clean up example files
FileUtils.rm_rf(File.join(__dir__, "templates")) if Dir.exist?(File.join(__dir__, "templates"))
