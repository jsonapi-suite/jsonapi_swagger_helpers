module JsonapiSwaggerHelpers
  class UpdateAction
    include JsonapiSwaggerHelpers::Writeable

    def action_name
      :update
    end

    def generate
      _self = self

      define_schema
      @node.operation :put do
        key :description, _self.description
        key :operationId, _self.operation_id
        key :tags, _self.all_tags

        _self.util.id_in_url(self) unless _self.singular

        parameter do
          key :name, :payload
          key :in, :body

          schema do
            key :'$ref', _self.request_schema_id
          end
        end

        response 200 do
          key :description, 'API Response'
        end
      end
    end
  end
end
