# frozen_string_literal: true

require "rails/generators"

module RubyLLM
  module Template
    module Generators
      class InstallGenerator < Rails::Generators::Base
        desc "Install RubyLLM Template system"

        def self.source_root
          @source_root ||= File.expand_path("templates", __dir__)
        end

          def create_initializer
          create_file "config/initializers/ruby_llm_template.rb", <<~RUBY
            # frozen_string_literal: true

            RubyLLM::Template.configure do |config|
                        # Set the directory where your prompts are stored
            # Default: Rails.root.join("app", "prompts")
            # config.template_directory = Rails.root.join("app", "prompts")
            end
          RUBY
        end

        def create_template_directory
          empty_directory "app/prompts"

          create_file "app/prompts/.keep", ""

          # Create an example template
          create_example_template
        end

        def show_readme
          say <<~MESSAGE

          RubyLLM Template has been installed!

          Prompts directory: app/prompts/
          Configuration: config/initializers/ruby_llm_template.rb

          Example usage:
            RubyLLM.chat.with_template(:extract_metadata, document: @document).complete

          Template structure:
            app/prompts/extract_metadata/
              ├── system.txt.erb    # System message
              ├── user.txt.erb      # User prompt
              ├── assistant.txt.erb # Assistant message (optional)
              └── schema.rb         # RubyLLM::Schema definition (optional)

          Get started by creating your first template!
          MESSAGE
        end

        private

        def create_example_template
          example_dir = "app/prompts/extract_metadata"
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

          create_file "#{example_dir}/schema.rb", <<~RUBY
          # frozen_string_literal: true

          # Schema definition using RubyLLM::Schema DSL
          # See: https://github.com/danielfriis/ruby_llm-schema

          RubyLLM::Schema.create do
            string :document_type, description: "The type of document (e.g., report, article, email)"

            array :key_topics, description: "Main topics discussed in the document" do
              string
            end

            array :important_dates, required: false, description: "Significant dates mentioned in the document" do
              string format: "date"
            end

            array :entities, required: false, description: "Named entities found in the document" do
              object do
                string :name
                string :type, enum: ["person", "organization", "location", "other"]
              end
            end
          end
          RUBY
        end
      end
    end
  end
end
