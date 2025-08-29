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
          schema_result = loader.render_template("schema", context)

          if schema_result
            if schema_result.is_a?(Class) && schema_result < RubyLLM::Schema
              # It's a schema class, pass it directly to with_schema
              with_schema(schema_result)
            elsif schema_result.respond_to?(:to_json_schema)
              # It's a RubyLLM::Schema instance
              schema_data = schema_result.to_json_schema
              with_schema(schema_data)
            end
          end
        end

        self
      end
    end
  end
end
