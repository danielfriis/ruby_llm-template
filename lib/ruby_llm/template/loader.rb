# frozen_string_literal: true

require "erb"
require "pathname"

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
        file_name = "#{role}.txt.erb"
        template_file = @template_path.join(file_name)

        return nil unless File.exist?(template_file)
        return nil unless SUPPORTED_ROLES.include?(role.to_s)

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

        Dir.glob("*.txt.erb", base: @template_path).map do |file|
          File.basename(file, ".txt.erb")
        end.select { |role| SUPPORTED_ROLES.include?(role) }
      end

      def template_exists?
        Dir.exist?(@template_path) && !available_roles.empty?
      end

      private

      def create_binding_context(context)
        # Create a new binding with the context variables available
        context.each do |key, value|
          define_singleton_method(key) { value }
        end

        binding
      end
    end
  end
end
