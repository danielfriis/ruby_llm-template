# frozen_string_literal: true

require "spec_helper"

RSpec.describe RubyLlm::Template do
  it "has a version number" do
    expect(RubyLlm::Template::VERSION).not_to be nil
  end

  describe ".configuration" do
    it "returns a configuration instance" do
      expect(described_class.configuration).to be_a(RubyLlm::Template::Configuration)
    end

    it "returns the same instance on multiple calls" do
      config1 = described_class.configuration
      config2 = described_class.configuration
      expect(config1).to be(config2)
    end
  end

  describe ".configure" do
    it "yields the configuration" do
      expect { |b| described_class.configure(&b) }.to yield_with_args(described_class.configuration)
    end

    it "allows setting template directory" do
      described_class.configure do |config|
        config.template_directory = "/custom/path"
      end

      expect(described_class.configuration.template_directory).to eq("/custom/path")
    end
  end

  describe ".reset_configuration!" do
    it "resets the configuration" do
      described_class.configure { |config| config.template_directory = "/test" }
      original_config = described_class.configuration

      described_class.reset_configuration!
      new_config = described_class.configuration

      expect(new_config).not_to be(original_config)
    end
  end
end
