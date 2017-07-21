module JsonapiSwaggerHelpers
  class CreateAction
    include JsonapiSwaggerHelpers::Writeable

    def action_name
      :create
    end

    def generate
      _self = self

      define_schema
      @node.operation :post do
        key :description, _self.description
        key :operationId, _self.operation_id
        key :tags, _self.all_tags

        parameter do
          key :name, :payload
          key :in, :body

          schema do
            key :'$ref', :"#{_self.strong_resource.name}_create"
          end
        end
      end
    end
  end
end
