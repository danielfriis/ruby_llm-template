# frozen_string_literal: true

module RubyLLM
  module Template
    class Railtie < Rails::Railtie
      initializer "ruby_llm_template.configure" do |app|
        # Set default template directory for Rails applications
        RubyLLM::Template.configure do |config|
          config.template_directory ||= app.root.join("app", "prompts")
        end
      end
    end
  end
end
