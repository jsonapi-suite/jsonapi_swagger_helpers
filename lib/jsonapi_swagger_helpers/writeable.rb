module JsonapiSwaggerHelpers
  module Writeable
    def self.included(klass)
      klass.class_eval do
        attr_reader :node,
          :controller,
          :resource,
          :description,
          :tags
      end
    end

    def initialize(node, controller, description: nil, tags: [])
      @node = node
      @controller = controller
      @resource = controller._jsonapi_compliable
      @description = description || default_description
      @tags = tags
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

      strong_resource.relations.each_pair do |relation_name, relation_config|
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

    def define_schema
      _self = self
      context.send(:swagger_schema, :"#{strong_resource.name}_#{action_name}") do
        _self.strong_resource.attributes.each_pair do |attribute, config|
          property attribute do
            key :type, config[:type] # TODO - swagger type?
          end
        end
      end

      _self.strong_resource.relations.each_pair do |relation_name, relation_config|
        context.send(:swagger_schema, :"#{strong_resource.name}_#{relation_name}_#{action_name}") do
          relation_config[:resource].attributes.each_pair do |attribute, config|
            property attribute do
              key :type, config[:type] # TODO - swagger type?
            end
          end
        end
      end
    end

    def generate
      _self = self

      define_schema
      @node.operation :post do
        key :description, _self.description
        key :operationId, _self.operation_id
        key :tags, _self.all_tags
      end
    end
  end
end
