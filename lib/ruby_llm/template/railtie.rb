# frozen_string_literal: true

module RubyLLM
  module Template
    class Railtie < Rails::Railtie
      # Register generators
      generators do
        require_relative "../../generators/ruby_llm/template/install_generator"
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
