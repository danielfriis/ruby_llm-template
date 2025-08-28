# frozen_string_literal: true

module RubyLlm
  module Template
    class Railtie < Rails::Railtie
      initializer "ruby_llm_template.configure" do |app|
        # Set default template directory for Rails applications
        RubyLlm::Template.configure do |config|
          config.template_directory ||= app.root.join("app", "templates")
        end
      end
    end
  end
end
