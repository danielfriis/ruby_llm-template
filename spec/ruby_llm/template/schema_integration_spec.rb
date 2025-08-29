# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Schema Integration" do
  let(:template_name) { "test_template" }
  let(:template_directory) { @tmpdir }
  let(:loader) { RubyLlm::Template::Loader.new(template_name, template_directory: template_directory) }

  before do
    RubyLlm::Template.configure do |config|
      config.template_directory = template_directory
    end
  end

  describe "RubyLLM::Schema integration" do
    context "when RubyLLM::Schema is available" do
      before do
        # Mock RubyLLM::Schema
        stub_const("RubyLLM::Schema", Class.new do
          def self.create(&block)
            instance = new
            instance.instance_eval(&block) if block_given?
            instance
          end

          def initialize
            @properties = {}
          end

          def string(name, **options)
            @properties[name] = {type: "string"}.merge(options)
          end

          def number(name, **options)
            @properties[name] = {type: "number"}.merge(options)
          end

          def array(name, of: nil, **options, &block)
            property = {type: "array"}.merge(options)
            property[:items] = {type: of.to_s} if of
            @properties[name] = property
          end

          def to_json_schema
            {
              name: "TestSchema",
              schema: {
                type: "object",
                properties: @properties,
                required: @properties.keys,
                additionalProperties: false
              }
            }
          end
        end)
      end

      context "with schema.rb file" do
        before do
          create_test_template(template_name, {
            system: "You are a helpful assistant.",
            user: "Process this: <%= input %>"
          })

          schema_content = <<~RUBY
            RubyLLM::Schema.create do
              string :title, description: "Document title"
              string :summary, description: "Brief summary"
              array :tags, of: :string, description: "Topic tags"
              number :confidence, description: "Confidence score"
            end
          RUBY

          File.write(File.join(template_directory, template_name, "schema.rb"), schema_content)
        end

        it "loads schema from .rb file" do
          schema = loader.load_schema_class(input: "test document")

          expect(schema).to respond_to(:to_json_schema)
          schema_data = schema.to_json_schema

          expect(schema_data[:schema][:type]).to eq("object")
          expect(schema_data[:schema][:properties]).to include(:title, :summary, :tags, :confidence)
        end

        it "makes context variables available in schema" do
          # Test that context variables can be accessed (though not used in this simple example)
          expect {
            loader.load_schema_class(input: "test document", max_tags: 5)
          }.not_to raise_error
        end
      end

      context "with both schema.rb and schema.txt.erb" do
        before do
          create_test_template(template_name, {
            system: "System message",
            schema: '{"type": "object", "properties": {"old": {"type": "string"}}}'
          })

          schema_rb_content = <<~RUBY
            RubyLLM::Schema.create do
              string :new_field, description: "New field from .rb file"
            end
          RUBY

          File.write(File.join(template_directory, template_name, "schema.rb"), schema_rb_content)
        end

        it "uses schema.rb and ignores schema.txt.erb" do
          result = loader.render_template("schema")

          expect(result).to respond_to(:to_json_schema)
          schema_data = result.to_json_schema
          expect(schema_data[:schema][:properties]).to include(:new_field)
          expect(schema_data[:schema][:properties]).not_to include(:old)
        end

        it "available_roles only includes schema once" do
          expect(loader.available_roles).to contain_exactly("system", "schema")
        end
      end
    end

    context "when RubyLLM::Schema is not available" do
      before do
        # Ensure RubyLLM::Schema is not defined
        hide_const("RubyLLM::Schema") if defined?(RubyLLM::Schema)

        create_test_template(template_name, {
          system: "System message"
        })

        File.write(File.join(template_directory, template_name, "schema.rb"), "# Schema content")
      end

      it "raises error when schema.rb exists but gem not installed" do
        expect {
          loader.render_template("schema")
        }.to raise_error(
          RubyLlm::Template::Error,
          /Schema file.*found but RubyLLM::Schema gem is not installed/
        )
      end
    end
  end

  describe "Chat Extension with Schema" do
    let(:chat_double) { double("Chat") }

    before do
      chat_double.extend(RubyLlm::Template::ChatExtension)
    end

    context "with schema.rb file" do
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

        create_test_template(template_name, {
          system: "System message"
        })

        schema_content = <<~RUBY
          RubyLLM::Schema.create do
            string :result, description: "Processing result"
          end
        RUBY

        File.write(File.join(template_directory, template_name, "schema.rb"), schema_content)
      end

      it "applies schema from .rb file using with_schema" do
        expect(chat_double).to receive(:add_message).with(role: "system", content: "System message")
        expect(chat_double).to receive(:with_schema).with(hash_including(
          name: "TestSchema",
          schema: hash_including(
            type: "object",
            properties: hash_including(:result)
          )
        ))

        chat_double.with_template(template_name.to_sym)
      end
    end
  end
end
