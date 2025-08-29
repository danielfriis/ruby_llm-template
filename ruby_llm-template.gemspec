# frozen_string_literal: true

require_relative "lib/ruby_llm/template/version"

Gem::Specification.new do |spec|
  spec.name = "ruby_llm-template"
  spec.version = RubyLlm::Template::VERSION
  spec.authors = ["Daniel Friis"]
  spec.email = ["d@friis.me"]

  spec.summary = "Template management system for RubyLLM - organize and reuse ERB templates for AI chat interactions"
  spec.description = "RubyLLM::Template provides a flexible template system for RubyLLM, allowing you to organize chat prompts, system messages, and schemas in ERB template files for easy reuse and maintenance."
  spec.homepage = "https://github.com/danielfriis/ruby_llm-template"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/danielfriis/ruby_llm-template"
  spec.metadata["changelog_uri"] = "https://github.com/danielfriis/ruby_llm-template/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "ruby_llm", ">= 1.0"
  spec.add_dependency "ruby_llm-schema", ">= 0.2.0"

  spec.add_development_dependency "rspec", "~> 3.12"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
