# frozen_string_literal: true

require_relative "template/version"
require_relative "template/configuration"
require_relative "template/loader"
require_relative "template/chat_extension"

# Load Rails integration if Rails is available
begin
  require "rails"
  require_relative "template/railtie"
rescue LoadError
  # Rails not available
end

module RubyLLM
  module Template
    class Error < StandardError; end

    def self.configuration
      @configuration ||= Configuration.new
    end

    def self.configure
      yield(configuration)
    end

    def self.reset_configuration!
      @configuration = nil
    end
  end
end

# Extend RubyLLM's Chat class if it's available
begin
  require "ruby_llm"

  if defined?(RubyLLM) && RubyLLM.respond_to?(:chat)
    # We need to extend the actual chat class returned by RubyLLM.chat
    # This is a monkey patch approach, but necessary for the API we want

    module RubyLLMChatTemplateExtension
      def self.extended(base)
        base.extend(RubyLLM::Template::ChatExtension)
      end
    end

    # Hook into RubyLLM.chat to extend the returned object
    module RubyLLMTemplateHook
      def chat(*args, **kwargs)
        chat_instance = super
        chat_instance.extend(RubyLLM::Template::ChatExtension)
        chat_instance
      end
    end

    if defined?(RubyLLM)
      RubyLLM.singleton_class.prepend(RubyLLMTemplateHook)
    end
  end
rescue LoadError
  # RubyLLM not available, extension will be loaded when it becomes available
end
