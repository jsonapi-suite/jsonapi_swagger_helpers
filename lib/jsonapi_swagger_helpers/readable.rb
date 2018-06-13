# frozen_string_literal: true

module JsonapiSwaggerHelpers
  module Readable
    def self.included(klass)
      klass.class_eval do
        attr_reader :node,
                    :controller,
                    :description,
                    :tags,
                    :singular
      end
    end

    def initialize(node, controller, description: nil, tags: [], singular: false)
      @node = node
      @controller = controller
      @description = description || default_description
      @tags = tags
      @singular = singular
    end

    def resource
      @resource = controller._jsonapi_compliable
      if @resource.is_a?(Hash)
        @resource = @resource[action_name]
      end
      @resource
    end

    def default_description
      "#{action_name.capitalize} Action"
    end

    def operation_id
      "#{controller.name.gsub('::', '-')}-#{action_name}"
    end

    def util
      JsonapiSwaggerHelpers::Util
    end

    def include_directive
      util.include_directive_for(controller, action_name)
    end

    def has_sideloads?
      include_directive.keys.length > 0
    end

    def has_extra_fields?
      resource.config[:extra_fields].keys.length > 1
    end

    def full_description
      "#{description}<br /><br />#{util.sideload_label(include_directive)}"
    end

    def all_tags
      tags + payload_tags
    end

    def payload_tags
      util.payload_tags_for(resource, include_directive.to_hash)
    end

    def operation_id
      "#{controller.name.gsub('::', '-')}-#{action_name}"
    end

    def each_stat
      resource.config[:stats].each_pair do |stat_name, opts|
        calculations = opts.calculations.keys - [:keys]
        calculations = calculations.join(', ')

        yield stat_name, calculations
      end
    end

    def each_association
      types = [jsonapi_type]
      resource_map = util.all_resources(resource, include_directive)
      resource_map.each_pair do |association_name, association_resource|
        resource_type = association_resource.config[:type]
        next if types.include?(resource_type)
        types << resource_type
        yield association_name, association_resource
      end
    end

    def jsonapi_type
      resource.config[:type]
    end

    def response_schema_id
      "#{operation_id}_#{action_name}_response"
    end

    def generate_response_schema!
      _self = self

      payloads = util.payloads_for(resource, include_directive.to_hash)
      JsonapiSwaggerHelpers.docs_controller.send(:swagger_schema, response_schema_id) do
        payloads.each do |p|
          property p.name do
            key :'$ref', p.name
          end
        end
      end
    end

    def generate
      raise 'override me'
    end
  end
end
