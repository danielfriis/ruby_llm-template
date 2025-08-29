# frozen_string_literal: true

require "spec_helper"

RSpec.describe RubyLlm::Template::Configuration do
  subject(:config) { described_class.new }

  describe "#template_directory" do
    context "when not set" do
      it "returns default directory" do
        expect(config.template_directory).to eq(File.join(Dir.pwd, "prompts"))
      end
    end

    context "when set" do
      it "returns the set directory" do
        config.template_directory = "/custom/path"
        expect(config.template_directory).to eq("/custom/path")
      end
    end

    context "when Rails is defined" do
      before do
        stub_const("Rails", double("Rails", root: double("Root", join: "/rails/app/prompts")))
      end

      it "returns Rails default directory" do
        expect(config.template_directory).to eq("/rails/app/prompts")
      end
    end
  end

  describe "#template_directory=" do
    it "sets the template directory" do
      config.template_directory = "/new/path"
      expect(config.instance_variable_get(:@template_directory)).to eq("/new/path")
    end
  end
end
