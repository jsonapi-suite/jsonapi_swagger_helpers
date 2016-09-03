module JsonapiSwaggerHelpers
  module StrongResourceMixin

    class Schemas
      include Swagger::Blocks

      def self.schema(name, &blk)
        swagger_schema(name, &blk)
      end
    end

    def strong_resource(controller, action)
      update   = action == :update
      resource = controller._strong_resources[action]
      opts     = { jsonapi_type: resource.jsonapi_type }

      if (attributes = strong_resource_attributes(resource, update)).present?
        opts[:attributes] = attributes
      end

      if (relationships = strong_resource_relationships(resource, update)).present?
        opts[:relationships] = relationships
      end

      jsonapi_payload(SecureRandom.uuid.to_sym, opts)
    end

    def strong_resource_attributes(resource, is_update = false)
      attributes = {}
      resource.attributes.each_pair do |name, opts|
        type = StrongResources.config.strong_params[opts[:type]][:swagger]
        attributes[name] = type

        if is_update
          if resource.destroy?
            attributes[:_destroy] = :boolean
          end

          if resource.delete?
            attributes[:_delete] = :boolean
          end
        end
      end

      attributes = attributes.slice(*resource.only) if !!resource.only
      attributes = attributes.except(*resource.except) if !!resource.except
      attributes
    end

    def strong_resource_relationships(resource, is_update = false)
      {}.tap do |relations|
        resource.relations.each_pair do |relation_name, opts|
          resource = opts[:resource]

          payload = {
            jsonapi_type: resource.jsonapi_type,
            id: true,
            array: resource.has_many?
          }

          if (attributes = strong_resource_attributes(resource, is_update)).present?
            payload[:attributes] = attributes
          end

          if (relationships = strong_resource_relationships(resource, is_update)).present?
            payload[:relationships] = relationships
          end

          relations[relation_name] = payload
        end
      end
    end

    def jsonapi_payload(schema_name, payload)
      jsonapi_input_schema(schema_name, payload)

      parameter do
        key :name, :payload
        key :in, :body

        schema do
          key :'$ref', schema_name
        end
      end
    end

    def jsonapi_input_schema(schema_name,
                                id: false,
                                jsonapi_type:,
                                attributes: nil,
                                relationships: nil)
      Schemas.schema(schema_name) do
        property :data do
          key :type, :object

          property :type do
            key :type, :string
            key :required, true
            key :enum, [jsonapi_type]
          end

          if id
            property :id do
              key :type, :string
            end
          end

          if attributes
            instance_exec(attributes, &SchemaHelpers.attributes_schema)
          end

          if relationships
            instance_exec(relationships, &SchemaHelpers.relationships_schema)
          end
        end
      end
    end

  end
end
