# frozen_string_literal: true

module JsonapiSwaggerHelpers
  module Writeable
    def self.included(klass)
      klass.class_eval do
        attr_reader :node,
                    :controller,
                    :resource,
                    :description,
                    :tags,
                    :singular
      end
    end

    def initialize(node, controller, description: nil, tags: [],
                   singular: false)
      @node = node
      @controller = controller
      @resource = controller._jsonapi_compliable
      @description = description || default_description
      @tags = tags
      @singular = singular
    end

    def util
      JsonapiSwaggerHelpers::Util
    end

    def action_name
      raise 'override me'
    end

    def default_description
      "#{action_name.to_s.capitalize} Action"
    end

    def operation_id
      "#{controller.name.gsub('::', '-')}-#{action_name}"
    end

    def all_tags
      tags + payload_tags
    end

    def payload_tags
      tags = [:"payload-#{strong_resource.name}_#{action_name}"]

      strong_resource.relations.each_pair do |relation_name, _relation_config|
        tags << :"payload-#{strong_resource.name}_#{relation_name}_#{action_name}"
      end

      tags
    end

    def context
      JsonapiSwaggerHelpers.docs_controller
    end

    def strong_resource
      controller._strong_resources[action_name]
    end

    def request_schema_id
      "#{operation_id}_#{action_name}_request"
    end

    def generate_request_schema!
      _self = self

      JsonapiSwaggerHelpers.docs_controller.send(:swagger_schema, request_schema_id) do
        property _self.strong_resource.name do
          key :'$ref', :"#{_self.strong_resource.name}_#{_self.action_name}"
        end

        _self.each_strong_relation(_self.strong_resource) do |relation_name, _relation_config|
          property relation_name do
            key :'$ref', :"#{_self.strong_resource.name}_#{relation_name}_#{_self.action_name}"
          end
        end
      end
    end

    def each_strong_relation(strong_resource)
      strong_resource.relations.each_pair do |relation_name, relation_config|
        yield relation_name, relation_config

        each_strong_relation(relation_config[:resource]) do |sub_relation_name, sub_relation_config|
          yield sub_relation_name, sub_relation_config
        end
      end
    end

    def define_schema
      generate_request_schema!

      _self = self
      context.send(:swagger_schema, :"#{strong_resource.name}_#{action_name}") do
        _self.strong_resource.attributes.each_pair do |attribute, config|
          property attribute do
            key :type, config[:type]
          end
        end
      end

      _self.each_strong_relation(_self.strong_resource) do |relation_name, relation_config|
        context.send(:swagger_schema, :"#{strong_resource.name}_#{relation_name}_#{action_name}") do
          relation_config[:resource].attributes.each_pair do |attribute, config|
            property attribute do
              key :type, config[:type]
            end
          end
        end
      end
    end

    def generate
      raise 'override me'
    end
  end
end
