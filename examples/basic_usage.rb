#!/usr/bin/env ruby
# frozen_string_literal: true

# Example of using RubyLLM::Template
# This file demonstrates basic usage without actually calling RubyLLM APIs

require_relative "../lib/ruby_llm/template"

# Configure template directory
RubyLLM::Template.configure do |config|
  config.template_directory = File.join(__dir__, "prompts")
end

# Create example prompts directory
prompts_dir = File.join(__dir__, "prompts", "extract_metadata")
FileUtils.mkdir_p(prompts_dir)

# Create example template files
File.write(File.join(prompts_dir, "system.txt.erb"), <<~ERB)
  You are an expert document analyzer. Your task is to extract metadata from the provided document.
  
  Please analyze the document carefully and extract relevant information such as:
  - Document type
  - Key topics  
  - Important dates
  - Main entities mentioned
  
  Provide your analysis in a structured format.
ERB

File.write(File.join(prompts_dir, "user.txt.erb"), <<~ERB)
  Please analyze the following document and extract its metadata:
  
  Document: <%= document %>
  
  <% if additional_context %>
  Additional context: <%= additional_context %>
  <% end %>
  
  Focus areas: <%= focus_areas.join(", ") if defined?(focus_areas) && focus_areas.any? %>
ERB

# Create schema.rb file using RubyLLM::Schema DSL
File.write(File.join(prompts_dir, "schema.rb"), <<~RUBY)
  # Mock RubyLLM::Schema for this example
  module RubyLLM
    class Schema
      def self.create(&block)
        instance = new
        instance.instance_eval(&block)
        instance
      end
      
      def initialize
        @schema = {type: "object", properties: {}, required: []}
      end
      
      def string(name, **options)
        @schema[:properties][name] = {type: "string"}.merge(options.except(:required))
        @schema[:required] << name unless options[:required] == false
      end
      
      def array(name, **options, &block)
        prop = {type: "array"}.merge(options.except(:required))
        prop[:items] = {type: "string"} if !block_given?
        @schema[:properties][name] = prop
        @schema[:required] << name unless options[:required] == false
      end
      
      def to_json_schema
        {name: "ExtractMetadataSchema", schema: @schema}
      end
    end
  end

  # The actual schema definition
  RubyLLM::Schema.create do
    string :document_type, description: "The type of document (e.g., report, article, email)"
    
    array :key_topics, description: "Main topics discussed in the document"
    
    array :important_dates, required: false, description: "Significant dates mentioned"
    
    # Context variables are available in schema.rb files
    focus_count = defined?(focus_areas) ? focus_areas&.length || 3 : 3
  end
RUBY

puts "🎯 RubyLLM::Template Example"
puts "=" * 40

# Mock chat object that demonstrates the extension
class MockChat
  include RubyLLM::Template::ChatExtension

  def initialize
    @messages = []
    @schema = nil
  end

  def add_message(role:, content:)
    @messages << {role: role, content: content}
    puts "📝 Added #{role} message: #{content[0..100]}#{"..." if content.length > 100}"
  end

  def with_schema(schema)
    @schema = schema
    if schema.is_a?(Hash) && schema[:schema]
      puts "📋 Schema applied: #{schema[:name]} with #{schema[:schema][:properties]&.keys&.length || 0} properties"
    else
      puts "📋 Schema applied with #{schema.keys.length} properties"
    end
    self
  end

  def complete
    puts "\n🤖 Chat would now be sent to AI with:"
    puts "   - #{@messages.length} messages"
    puts "   - Schema: #{@schema ? "Yes" : "No"}"
    puts "\n💬 Messages:"
    @messages.each_with_index do |msg, i|
      puts "   #{i + 1}. [#{msg[:role].upcase}] #{msg[:content][0..80]}#{"..." if msg[:content].length > 80}"
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
    focus_areas: ["revenue", "challenges", "projections"]).complete
rescue RubyLLM::Template::Error => e
  puts "❌ Error: #{e.message}"
end

puts "\n✅ Example completed successfully!"
puts "\nTo use with real RubyLLM:"
puts "  RubyLLM.chat.with_template(:extract_metadata, document: @document).complete"

# Clean up example files
FileUtils.rm_rf(File.join(__dir__, "prompts")) if Dir.exist?(File.join(__dir__, "prompts"))
