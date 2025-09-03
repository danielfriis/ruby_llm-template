# frozen_string_literal: true

require "ruby_llm/template"
require "rspec"
require "tmpdir"
require "fileutils"

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  # Create a temporary directory for each test
  config.around(:each) do |example|
    Dir.mktmpdir do |tmpdir|
      @tmpdir = tmpdir
      example.run
    end
  ensure
    RubyLLM::Template.reset_configuration!
  end

  config.before(:each) do
    # Reset configuration before each test
    RubyLLM::Template.reset_configuration!
  end
end

def create_test_template(name, templates = {})
  template_dir = File.join(@tmpdir, name.to_s)
  FileUtils.mkdir_p(template_dir)

  templates.each do |role, content|
    File.write(File.join(template_dir, "#{role}.txt.erb"), content)
  end

  template_dir
end
