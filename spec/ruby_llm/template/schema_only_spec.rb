# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Schema-only Support" do
  let(:template_name) { "test_template" }
  let(:template_directory) { @tmpdir }
  let(:loader) { RubyLLM::Template::Loader.new(template_name, template_directory: template_directory) }

  before do
    RubyLLM::Template.configure do |config|
      config.template_directory = template_directory
    end
  end

  describe "schema.rb without RubyLLM::Schema gem" do
    before do
      # Ensure RubyLLM::Schema is not defined
      hide_const("RubyLLM::Schema") if defined?(RubyLLM::Schema)

      create_test_template(template_name, {
        system: "System message"
      })

      File.write(File.join(template_directory, template_name, "schema.rb"), <<~RUBY)
        RubyLLM::Schema.create do
          string :name
        end
      RUBY
    end

    it "raises error when schema.rb exists but gem is not installed" do
      expect {
        loader.render_template("schema")
      }.to raise_error(
        RubyLLM::Template::Error,
        /Schema file 'test_template\/schema.rb' found but RubyLLM::Schema gem is not installed/
      )
    end

    it "includes schema in available_roles even without gem" do
      expect(loader.available_roles).to include("schema")
    end

    it "template_exists? returns true even with schema.rb without gem" do
      expect(loader.template_exists?).to be true
    end
  end

  describe "schema.txt.erb files are ignored" do
    before do
      create_test_template(template_name, {
        system: "System message",
        schema: '{"type": "object", "properties": {"old": {"type": "string"}}}'
      })
    end

    it "does not include schema.txt.erb in available_roles" do
      expect(loader.available_roles).to contain_exactly("system")
      expect(loader.available_roles).not_to include("schema")
    end

    it "returns nil when trying to render schema.txt.erb" do
      result = loader.render_template("schema")
      expect(result).to be_nil
    end
  end

  describe "Chat extension with schema.rb only" do
    let(:chat_double) { double("Chat") }

    before do
      chat_double.extend(RubyLLM::Template::ChatExtension)
    end

    context "when schema.rb exists but gem not installed" do
      before do
        hide_const("RubyLLM::Schema") if defined?(RubyLLM::Schema)

        create_test_template(template_name, {
          system: "System message"
        })

        File.write(File.join(template_directory, template_name, "schema.rb"), "RubyLLM::Schema.create { }")
      end

      it "raises error during with_template call" do
        expect(chat_double).to receive(:add_message).with(role: "system", content: "System message")

        expect {
          chat_double.with_template(template_name.to_sym)
        }.to raise_error(
          RubyLLM::Template::Error,
          /Schema file.*found but RubyLLM::Schema gem is not installed/
        )
      end
    end

    context "when only schema.txt.erb exists" do
      before do
        create_test_template(template_name, {
          system: "System message",
          schema: '{"type": "object"}'
        })
      end

      it "does not call with_schema since schema.txt.erb is ignored" do
        expect(chat_double).to receive(:add_message).with(role: "system", content: "System message")
        expect(chat_double).not_to receive(:with_schema)

        chat_double.with_template(template_name.to_sym)
      end
    end
  end

  describe "mixed schema files" do
    before do
      stub_const("RubyLLM::Schema", Class.new do
        def self.create(&block)
          instance = new
          instance.instance_eval(&block)
          instance
        end

        def initialize
          @properties = {}
        end

        def string(name, **options)
          @properties[name] = {type: "string"}.merge(options)
        end

        def to_json_schema
          {name: "TestSchema", schema: {type: "object", properties: @properties}}
        end
      end)

      create_test_template(template_name, {
        system: "System message",
        schema: '{"type": "object", "properties": {"old_field": {"type": "string"}}}'
      })

      # Add schema.rb file
      File.write(File.join(template_directory, template_name, "schema.rb"), <<~RUBY)
        RubyLLM::Schema.create do
          string :new_field, description: "New field from .rb file"
        end
      RUBY
    end

    it "only uses schema.rb and ignores schema.txt.erb" do
      result = loader.render_template("schema")

      expect(result).to respond_to(:to_json_schema)
      schema_data = result.to_json_schema
      expect(schema_data[:schema][:properties]).to include(:new_field)
      expect(schema_data[:schema][:properties]).not_to include(:old_field)
    end

    it "available_roles only includes schema once" do
      expect(loader.available_roles).to contain_exactly("system", "schema")
    end
  end
end
