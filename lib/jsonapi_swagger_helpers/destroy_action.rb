module JsonapiSwaggerHelpers
  class DestroyAction
    include JsonapiSwaggerHelpers::Writeable

    def action_name
      :destroy
    end

    def generate
      _self = self

      @node.operation :delete do
        key :description, _self.description
        key :operationId, _self.operation_id
        key :tags, _self.tags

        _self.util.id_in_url(self)

        response 200 do
          key :description, 'API Response'
        end
      end
    end
  end
end
