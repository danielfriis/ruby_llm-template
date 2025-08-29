# frozen_string_literal: true

require "erb"
require "pathname"

begin
  require "ruby_llm/schema"
rescue LoadError
  # RubyLLM::Schema not available, schema.rb files won't work
end

module RubyLlm
  module Template
    class Loader
      SUPPORTED_ROLES = %w[system user assistant schema].freeze

      def initialize(template_name, template_directory: nil)
        @template_name = template_name.to_s
        @template_directory = Pathname.new(template_directory || RubyLlm::Template.configuration.template_directory)
        @template_path = @template_directory.join(@template_name)
      end

      def render_template(role, context = {})
        return nil unless SUPPORTED_ROLES.include?(role.to_s)

        # Handle schema role specially - only support .rb files
        if role.to_s == "schema"
          return render_schema_template(context)
        end

        # Handle regular ERB template
        file_name = "#{role}.txt.erb"
        template_file = @template_path.join(file_name)

        return nil unless File.exist?(template_file)

        template_content = File.read(template_file)
        erb = ERB.new(template_content)

        # Create a binding with the context variables
        binding_context = create_binding_context(context)
        erb.result(binding_context)
      rescue => e
        raise Error, "Failed to render template '#{@template_name}/#{file_name}': #{e.message}"
      end

      def available_roles
        return [] unless Dir.exist?(@template_path)

        roles = []

        # Check for ERB templates (excluding schema.txt.erb)
        Dir.glob("*.txt.erb", base: @template_path).each do |file|
          role = File.basename(file, ".txt.erb")
          next if role == "schema" # Skip schema.txt.erb files
          roles << role if SUPPORTED_ROLES.include?(role)
        end

        # Check for schema.rb file
        if File.exist?(@template_path.join("schema.rb"))
          roles << "schema" unless roles.include?("schema")
        end

        roles.uniq
      end

      def template_exists?
        Dir.exist?(@template_path) && !available_roles.empty?
      end

      def load_schema_class(context = {})
        schema_file = @template_path.join("schema.rb")
        return nil unless File.exist?(schema_file)
        return nil unless defined?(RubyLLM::Schema)

        # Load the schema file in a clean context
        schema_content = File.read(schema_file)

        # Create a context for evaluating the schema
        schema_context = create_schema_context(context)

        # Evaluate the schema file and return the result
        result = schema_context.instance_eval(schema_content, schema_file.to_s)

        # If the result is a class that inherits from RubyLLM::Schema, instantiate it
        if result.is_a?(Class) && result < RubyLLM::Schema
          result.new
        elsif result.respond_to?(:to_json_schema)
          result
        else
          raise Error, "Schema file must return a RubyLLM::Schema class or instance"
        end
      rescue => e
        raise Error, "Failed to load schema from '#{@template_name}/schema.rb': #{e.message}"
      end

      private

      def render_schema_template(context = {})
        # Only support schema.rb files with RubyLLM::Schema
        schema_instance = load_schema_class(context)
        return schema_instance if schema_instance

        # If there's a schema.rb file but RubyLLM::Schema isn't available, error
        schema_file = @template_path.join("schema.rb")
        if File.exist?(schema_file) && !defined?(RubyLLM::Schema)
          raise Error, "Schema file '#{@template_name}/schema.rb' found but RubyLLM::Schema gem is not installed. Add 'gem \"ruby_llm-schema\"' to your Gemfile."
        end

        nil
      end

      def create_binding_context(context)
        # Create a new binding with the context variables available
        context.each do |key, value|
          define_singleton_method(key) { value }
        end

        binding
      end

      def create_schema_context(context)
        # Create an object that has access to context variables and RubyLLM::Schema methods
        schema_context = Object.new

        # Add context variables as instance variables and methods
        context.each do |key, value|
          schema_context.instance_variable_set("@#{key}", value)
          schema_context.define_singleton_method(key) { value }
        end

        schema_context
      end
    end
  end
end
