# frozen_string_literal: true

require "rails/generators"

module RubyLlmTemplate
  module Generators
    class InstallGenerator < Rails::Generators::Base
      desc "Install RubyLLM Template system"

      def self.source_root
        @source_root ||= File.expand_path("templates", __dir__)
      end

      def create_initializer
        create_file "config/initializers/ruby_llm_template.rb", <<~RUBY
          # frozen_string_literal: true

          RubyLlm::Template.configure do |config|
            # Set the directory where your templates are stored
            # Default: Rails.root.join("app", "templates")
            # config.template_directory = Rails.root.join("app", "templates")
          end
        RUBY
      end

      def create_template_directory
        empty_directory "app/templates"

        create_file "app/templates/.keep", ""

        # Create an example template
        create_example_template
      end

      def show_readme
        say <<~MESSAGE
          
          RubyLLM Template has been installed!
          
          Template directory: app/templates/
          Configuration: config/initializers/ruby_llm_template.rb
          
          Example usage:
            RubyLLM.chat.with_template(:extract_metadata, document: @document).complete
          
          Template structure:
            app/templates/extract_metadata/
              ├── system.txt.erb    # System message
              ├── user.txt.erb      # User prompt
              ├── assistant.txt.erb # Assistant message (optional)
              └── schema.txt.erb    # JSON schema (optional)
          
          Get started by creating your first template!
        MESSAGE
      end

      private

      def create_example_template
        example_dir = "app/templates/extract_metadata"
        empty_directory example_dir

        create_file "#{example_dir}/system.txt.erb", <<~ERB
          You are an expert document analyzer. Your task is to extract metadata from the provided document.
          
          Please analyze the document carefully and extract relevant information such as:
          - Document type
          - Key topics
          - Important dates
          - Main entities mentioned
          
          Provide your analysis in a structured format.
        ERB

        create_file "#{example_dir}/user.txt.erb", <<~ERB
          Please analyze the following document and extract its metadata:
          
          <% if defined?(document) && document %>
          Document: <%= document %>
          <% else %>
          [Document content will be provided here]
          <% end %>
          
          <% if defined?(additional_context) && additional_context %>
          Additional context: <%= additional_context %>
          <% end %>
        ERB

        create_file "#{example_dir}/schema.txt.erb", <<~ERB
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
      end
    end
  end
end
