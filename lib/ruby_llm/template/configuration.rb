# frozen_string_literal: true

module RubyLlm
  module Template
    class Configuration
      attr_writer :template_directory

      def initialize
        @template_directory = nil
      end

      def template_directory
        @template_directory || default_template_directory
      end

      private

      def default_template_directory
        if defined?(Rails) && Rails.respond_to?(:root) && Rails.root
          Rails.root.join("app", "prompts")
        else
          File.join(Dir.pwd, "prompts")
        end
      end
    end
  end
end
