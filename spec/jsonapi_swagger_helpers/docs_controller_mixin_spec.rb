# frozen_string_literal: true

require 'spec_helper'
require 'active_support/concern'
require 'active_support/inflector'
require 'jsonapi_compliable'
require 'strong_resources'

# mock Rails
unless defined? Rails
  class Rails
    def self.root
      []
    end
  end
end

# resource
class EmployeeResource < JsonapiCompliable::Resource
  type :employees
end

# strong resource
StrongResources.configure do
  strong_resource :employees do
    attribute :name, :string
    attribute :email, :string
  end
end

# helper methods
module TestHelpers
  def build_docs_controller
    Class.new do
      include JsonapiSwaggerHelpers::DocsControllerMixin

      def render(json:)
        json
      end

      swagger_root do
        key :swagger, '2.0'
        info do
          key :version, '1.0.0'
          key :title, 'Swagger Petstore'
        end
      end
    end
  end

  def build_controller_with(actions:)
    Class.new do
      singleton_class.class_eval do
        define_method(:action_methods) { actions }

        def name
          'EmployeesController'
        end
      end
      include JsonapiCompliable::Base
      include StrongResources::Controller::Mixin

      jsonapi resource: EmployeeResource

      strong_resource :employees
    end
  end

  def hash_fetch_path(hash, path)
    path.split('.').inject(hash) do |current_hash, key|
      current_hash.fetch(key) { current_hash.fetch(key.to_sym) }
    end
  end
end

# register payload
JsonapiSpecHelpers::Payload.register(:employees) do
  key(:name, allow_nil: true)
  key(:email)
end

RSpec.describe JsonapiSwaggerHelpers::DocsControllerMixin do
  include TestHelpers

  let(:root_schema) { 'http://jsonapi.org/format' }

  describe '#jsonapi_resource' do
    let(:path) { '/v1/resources' }
    let(:controller) { build_controller_with(actions: actions) }
    let(:docs_controller) { build_docs_controller }
    let(:swagger_doc) { docs_controller.new.index }
    let(:id_param) do
      { name: :id, in: :path, type: :string, required: true,
        description: 'record id' }
    end
    let(:sparse_field_param) do
      { description: %(<a href="#{root_schema}/#fetching-sparse-fieldsets">)\
        'JSONAPI Sparse Fieldset</a>',
        name: 'fields[employees]', in: :query, type: :string,
        required: false }
    end

    before do
      allow(JsonapiSwaggerHelpers::Util)
        .to receive(:controller_for).with(path).and_return(controller)
    end

    describe 'GET /resources' do
      subject { hash_fetch_path(swagger_doc, 'paths./v1/resources.get') }
      before { docs_controller.jsonapi_resource(path) }

      let(:actions) { %(index) }
      let(:sort_param) do
        { description: %(<a href="#{root_schema}/#fetching-sorting">)\
                       'JSONAPI Sorting</a>',
          name: :sort, in: :query, type: :string, required: false }
      end
      let(:page_size_param) do
        { description: %(<a href="#{root_schema}/#fetching-pagination">)\
                       'JSONAPI Page Size</a>',
          name: 'page[size]', in: :query, type: :string, required: false }
      end
      let(:page_num_param) do
        { description: %(<a href="#{root_schema}/#fetching-pagination">)\
                       'JSONAPI Page Number</a>',
          name: 'page[number]', in: :query, type: :string, required: false }
      end

      it { is_expected.to include(description: be_instance_of(String)) }
      it { is_expected.to include(operationId: 'EmployeesController-index') }
      it { is_expected.to include(responses: include(200)) }
      it { is_expected.to include(tags: ['payload-employees']) }
      it { is_expected.to include(parameters: include(sort_param)) }
      it { is_expected.to include(parameters: include(page_size_param)) }
      it { is_expected.to include(parameters: include(page_num_param)) }
      it { is_expected.to include(parameters: include(sparse_field_param)) }
    end

    describe 'GET /resources/:id' do
      subject { hash_fetch_path(swagger_doc, 'paths./v1/resources/{id}.get') }
      before { docs_controller.jsonapi_resource(path) }

      let(:actions) { %(show) }

      it { is_expected.to include(description: be_instance_of(String)) }
      it { is_expected.to include(operationId: 'EmployeesController-show') }
      it { is_expected.to include(responses: include(200)) }
      it { is_expected.to include(tags: ['payload-employees']) }
      it { is_expected.to include(parameters: include(sparse_field_param)) }
      it { is_expected.to include(parameters: include(id_param)) }
    end

    describe 'POST /resources' do
      subject { hash_fetch_path(swagger_doc, 'paths./v1/resources.post') }
      before { docs_controller.jsonapi_resource(path) }

      let(:actions) { %(create) }
      let(:post_param) do
        { name: :payload, in: :body, schema: {
          :$ref => '#/definitions/EmployeesController-create_create_request'
        } }
      end

      it { is_expected.to include(description: be_instance_of(String)) }
      it { is_expected.to include(operationId: 'EmployeesController-create') }
      it { is_expected.to include(responses: include(200)) }
      it { is_expected.to include(tags: ['payload-employees_create']) }
      it { is_expected.to include(parameters: include(post_param)) }

      describe '#/definitions/employees_create' do
        subject do
          hash_fetch_path(swagger_doc,
                          'definitions.employees_create.properties')
        end

        it { is_expected.to include(name: { type: :string }) }
        it { is_expected.to include(email: { type: :string }) }
      end
    end

    describe 'PUT /resources/:id' do
      subject { hash_fetch_path(swagger_doc, 'paths./v1/resources/{id}.put') }
      before { docs_controller.jsonapi_resource(path) }

      let(:actions) { %(update) }
      let(:update_param) do
        { name: :payload, in: :body, schema: {
          :$ref => '#/definitions/EmployeesController-update_update_request'
        } }
      end

      it { is_expected.to include(description: be_instance_of(String)) }
      it { is_expected.to include(operationId: 'EmployeesController-update') }
      it { is_expected.to include(responses: include(200)) }
      it { is_expected.to include(tags: ['payload-employees_update']) }
      it { is_expected.to include(parameters: include(update_param)) }
      it { is_expected.to include(parameters: include(id_param)) }

      describe '#/definitions/employees_update' do
        subject do
          hash_fetch_path(swagger_doc,
                          'definitions.employees_update.properties')
        end

        it { is_expected.to include(name: { type: :string }) }
        it { is_expected.to include(email: { type: :string }) }
      end
    end

    describe 'DELETE /resources/:id' do
      subject do
        hash_fetch_path(swagger_doc, 'paths./v1/resources/{id}.delete')
      end
      before { docs_controller.jsonapi_resource(path) }

      let(:actions) { %(destroy) }

      it { is_expected.to include(description: be_instance_of(String)) }
      it { is_expected.to include(operationId: 'EmployeesController-destroy') }
      it { is_expected.to include(responses: include(200)) }
      it { is_expected.to include(parameters: include(id_param)) }
    end

    context 'singular resource' do
      let(:path) { '/v1/resource' }

      describe 'GET /resource' do
        subject { hash_fetch_path(swagger_doc, 'paths./v1/resource.get') }
        before { docs_controller.jsonapi_resource(path, singular: true) }

        let(:actions) { %(show) }

        it { is_expected.to include(description: be_instance_of(String)) }
        it { is_expected.to include(operationId: 'EmployeesController-show') }
        it { is_expected.to include(responses: include(200)) }
        it { is_expected.to include(tags: ['payload-employees']) }
        it { is_expected.to include(parameters: include(sparse_field_param)) }
        it { is_expected.not_to include(parameters: include(id_param)) }
      end

      describe 'POST /resources' do
        subject { hash_fetch_path(swagger_doc, 'paths./v1/resource.post') }
        before { docs_controller.jsonapi_resource(path, singular: true) }

        let(:actions) { %(create) }
        let(:post_param) do
          { name: :payload, in: :body, schema: {
            :$ref => '#/definitions/EmployeesController-create_create_request'
          } }
        end

        it { is_expected.to include(description: be_instance_of(String)) }
        it { is_expected.to include(operationId: 'EmployeesController-create') }
        it { is_expected.to include(responses: include(200)) }
        it { is_expected.to include(tags: ['payload-employees_create']) }
        it { is_expected.to include(parameters: include(post_param)) }

        describe '#/definitions/employees_create' do
          subject do
            hash_fetch_path(swagger_doc,
                            'definitions.employees_create.properties')
          end

          it { is_expected.to include(name: { type: :string }) }
          it { is_expected.to include(email: { type: :string }) }
        end
      end

      describe 'PUT /resource' do
        subject { hash_fetch_path(swagger_doc, 'paths./v1/resource.put') }
        before { docs_controller.jsonapi_resource(path, singular: true) }

        let(:actions) { %(update) }
        let(:update_param) do
          { name: :payload, in: :body, schema: {
            :$ref => '#/definitions/EmployeesController-update_update_request'
          } }
        end

        it { is_expected.to include(description: be_instance_of(String)) }
        it { is_expected.to include(operationId: 'EmployeesController-update') }
        it { is_expected.to include(responses: include(200)) }
        it { is_expected.to include(tags: ['payload-employees_update']) }
        it { is_expected.to include(parameters: include(update_param)) }
        it { is_expected.not_to include(parameters: include(id_param)) }

        describe '#/definitions/employees_update' do
          subject do
            hash_fetch_path(swagger_doc,
                            'definitions.employees_update.properties')
          end

          it { is_expected.to include(name: { type: :string }) }
          it { is_expected.to include(email: { type: :string }) }
        end
      end

      describe 'DELETE /resource' do
        subject do
          hash_fetch_path(swagger_doc, 'paths./v1/resource.delete')
        end
        before { docs_controller.jsonapi_resource(path, singular: true) }

        let(:actions) { %(destroy) }

        it { is_expected.to include(description: be_instance_of(String)) }
        it do
          is_expected.to include(operationId: 'EmployeesController-destroy')
        end
        it { is_expected.to include(responses: include(200)) }
        it { is_expected.not_to include(parameters: include(id_param)) }
      end
    end
  end
end
