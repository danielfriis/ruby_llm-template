# frozen_string_literal: true

module RubyLlm
  module Template
    module ChatExtension
      def with_template(template_name, context = {})
        loader = RubyLlm::Template::Loader.new(template_name)

        unless loader.template_exists?
          raise RubyLlm::Template::Error, "Template '#{template_name}' not found in #{RubyLlm::Template.configuration.template_directory}"
        end

        # Apply templates in a specific order to maintain conversation flow
        template_order = ["system", "user", "assistant"]

        template_order.each do |role|
          next unless loader.available_roles.include?(role)

          content = loader.render_template(role, context)
          next unless content && !content.strip.empty?

          add_message(role: role, content: content.strip)
        end

        # Handle schema separately if it exists
        if loader.available_roles.include?("schema")
          schema_content = loader.render_template("schema", context)
          if schema_content && !schema_content.strip.empty?
            # Assume schema content is JSON that should be parsed
            begin
              require "json"
              schema_data = JSON.parse(schema_content.strip)
              with_schema(schema_data)
            rescue JSON::ParserError => e
              raise RubyLlm::Template::Error, "Invalid JSON in schema template: #{e.message}"
            end
          end
        end

        self
      end
    end
  end
end
