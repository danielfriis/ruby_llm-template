# frozen_string_literal: true

require "spec_helper"

RSpec.describe RubyLLM::Template::ChatExtension do
  let(:chat_double) { double("Chat") }
  let(:template_directory) { @tmpdir }

  before do
    chat_double.extend(described_class)

    RubyLLM::Template.configure do |config|
      config.template_directory = template_directory
    end
  end

  describe "#with_template" do
    context "when template exists" do
      before do
        create_test_template("test_template", {
          system: "You are a helpful assistant.",
          user: "Hello, <%= name %>!",
          assistant: "Hi there!"
        })
      end

      it "adds messages in correct order" do
        expect(chat_double).to receive(:add_message).with(role: "system", content: "You are a helpful assistant.")
        expect(chat_double).to receive(:add_message).with(role: "user", content: "Hello, Alice!")
        expect(chat_double).to receive(:add_message).with(role: "assistant", content: "Hi there!")

        result = chat_double.with_template(:test_template, name: "Alice")
        expect(result).to be(chat_double)
      end

      it "skips empty content" do
        create_test_template("empty_template", {
          system: "System message",
          user: "   \n\t   "  # Only whitespace
        })

        expect(chat_double).to receive(:add_message).with(role: "system", content: "System message")
        expect(chat_double).not_to receive(:add_message).with(hash_including(role: "user"))

        chat_double.with_template(:empty_template)
      end
    end

    context "when template has schema.rb" do
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
            {
              name: "TestSchema",
              schema: {
                type: "object",
                properties: @properties,
                required: @properties.keys
              }
            }
          end
        end)

        create_test_template("schema_template", {
          system: "System message"
        })

        File.write(File.join(template_directory, "schema_template", "schema.rb"), <<~RUBY)
          RubyLLM::Schema.create do
            string :name, description: "User name"
          end
        RUBY
      end

      it "applies schema using with_schema" do
        expect(chat_double).to receive(:add_message).with(role: "system", content: "System message")
        expect(chat_double).to receive(:with_schema).with(hash_including(
          name: "TestSchema",
          schema: hash_including(
            type: "object",
            properties: hash_including(:name)
          )
        ))

        chat_double.with_template(:schema_template)
      end
    end

    context "when schema.txt.erb exists (should be ignored)" do
      before do
        create_test_template("ignored_schema", {
          system: "System message",
          schema: '{"type": "object", "properties": {"name": {"type": "string"}}}'
        })
      end

      it "does not call with_schema since schema.txt.erb is ignored" do
        expect(chat_double).to receive(:add_message).with(role: "system", content: "System message")
        expect(chat_double).not_to receive(:with_schema)

        chat_double.with_template(:ignored_schema)
      end
    end

    context "when template does not exist" do
      it "raises an error" do
        expect {
          chat_double.with_template(:nonexistent_template)
        }.to raise_error(RubyLLM::Template::Error, /Template 'nonexistent_template' not found/)
      end
    end

    context "when template directory is not configured" do
      before do
        RubyLLM::Template.configure do |config|
          config.template_directory = "/nonexistent/path"
        end
      end

      it "raises an error" do
        expect {
          chat_double.with_template(:any_template)
        }.to raise_error(RubyLLM::Template::Error, /Template 'any_template' not found/)
      end
    end
  end
end
