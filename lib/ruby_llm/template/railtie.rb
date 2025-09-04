# frozen_string_literal: true

module RubyLLM
  module Template
    class Railtie < Rails::Railtie
      # Configure Zeitwerk inflections for proper LLM acronym handling
      initializer "ruby_llm_template.inflections", before: :set_autoload_paths do |app|
        if app.config.respond_to?(:autoload_inflections)
          app.config.autoload_inflections["ruby_llm"] = "RubyLLM"
        end
        
        # Also configure ActiveSupport inflections for consistency
        ActiveSupport::Inflector.inflections do |inflect|
          inflect.acronym "LLM"
        end
      end

      initializer "ruby_llm_template.configure" do |app|
        # Set default template directory for Rails applications
        RubyLLM::Template.configure do |config|
          config.template_directory ||= app.root.join("app", "prompts")
        end
      end
    end
  end
end
