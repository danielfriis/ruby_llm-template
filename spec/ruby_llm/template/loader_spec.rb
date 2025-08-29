# frozen_string_literal: true

require "spec_helper"

RSpec.describe RubyLlm::Template::Loader do
  let(:template_name) { "test_template" }
  let(:template_directory) { @tmpdir }
  let(:loader) { described_class.new(template_name, template_directory: template_directory) }

  describe "#render_template" do
    context "when template file exists" do
      before do
        create_test_template(template_name, {
          system: "You are a helpful assistant.",
          user: "Hello, <%= name %>! How are you today?"
        })
      end

      it "renders system template without context" do
        result = loader.render_template("system")
        expect(result).to eq("You are a helpful assistant.")
      end

      it "renders user template with context" do
        result = loader.render_template("user", name: "Alice")
        expect(result).to eq("Hello, Alice! How are you today?")
      end
    end

    context "when template file does not exist" do
      it "returns nil" do
        result = loader.render_template("nonexistent")
        expect(result).to be_nil
      end
    end

    context "when schema.rb file exists" do
      before do
        # Mock RubyLLM::Schema availability
        stub_const("RubyLLM::Schema", Class.new do
          def self.create(&block)
            schema_instance = new
            schema_instance.instance_eval(&block) if block_given?
            schema_instance
          end

          def initialize
            @properties = {}
          end

          def string(name, **options)
            @properties[name] = {type: "string"}.merge(options)
          end

          def to_json_schema
            {
              type: "object",
              properties: @properties,
              required: @properties.keys
            }
          end
        end)

        schema_content = <<~RUBY
          RubyLLM::Schema.create do
            string :name, description: "Person's name"
            string :email, description: "Email address"
          end
        RUBY

        create_test_template(template_name, {})
        File.write(File.join(template_directory, template_name, "schema.rb"), schema_content)
      end

      it "loads and returns schema instance" do
        result = loader.render_template("schema")
        expect(result).to respond_to(:to_json_schema)

        schema_data = result.to_json_schema
        expect(schema_data[:type]).to eq("object")
        expect(schema_data[:properties]).to include(:name, :email)
      end

      it "includes schema in available_roles" do
        expect(loader.available_roles).to include("schema")
      end
    end

    context "when role is not supported" do
      before do
        create_test_template(template_name, {invalid: "Invalid role content"})
      end

      it "returns nil for unsupported role" do
        result = loader.render_template("invalid")
        expect(result).to be_nil
      end
    end

    context "when ERB template has errors" do
      before do
        create_test_template(template_name, {system: "<%= undefined_variable %>"})
      end

      it "raises an error with descriptive message" do
        expect {
          loader.render_template("system")
        }.to raise_error(RubyLlm::Template::Error, /Failed to render template/)
      end
    end
  end

  describe "#available_roles" do
    context "when template directory exists with valid templates" do
      before do
        create_test_template(template_name, {
          system: "System content",
          user: "User content",
          invalid: "Invalid content"
        })
      end

      it "returns only supported roles" do
        expect(loader.available_roles).to contain_exactly("system", "user")
      end
    end

    context "when template directory has schema.txt.erb file" do
      before do
        create_test_template(template_name, {
          system: "System content",
          schema: '{"type": "object"}'
        })
      end

      it "excludes schema.txt.erb from available roles" do
        expect(loader.available_roles).to contain_exactly("system")
        expect(loader.available_roles).not_to include("schema")
      end
    end

    context "when template directory has schema.rb file" do
      before do
        create_test_template(template_name, {system: "System content"})
        File.write(File.join(template_directory, template_name, "schema.rb"), "# Schema")
      end

      it "includes schema in available roles" do
        expect(loader.available_roles).to contain_exactly("system", "schema")
      end
    end

    context "when template directory does not exist" do
      it "returns empty array" do
        expect(loader.available_roles).to eq([])
      end
    end
  end

  describe "#template_exists?" do
    context "when template directory exists with templates" do
      before do
        create_test_template(template_name, {system: "Content"})
      end

      it "returns true" do
        expect(loader.template_exists?).to be true
      end
    end

    context "when template directory does not exist" do
      it "returns false" do
        expect(loader.template_exists?).to be false
      end
    end

    context "when template directory exists but has no valid templates" do
      before do
        FileUtils.mkdir_p(File.join(template_directory, template_name))
      end

      it "returns false" do
        expect(loader.template_exists?).to be false
      end
    end
  end

  describe "SUPPORTED_ROLES" do
    it "includes expected roles" do
      expect(described_class::SUPPORTED_ROLES).to include("system", "user", "assistant", "schema")
    end
  end
end
