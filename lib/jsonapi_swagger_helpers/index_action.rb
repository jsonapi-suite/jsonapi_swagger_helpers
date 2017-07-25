module JsonapiSwaggerHelpers
  class IndexAction
    include JsonapiSwaggerHelpers::Readable

    def action_name
      :index
    end

    def generate
      _self = self
      generate_response_schema!

      @node.operation :get do
        key :description, _self.full_description
        key :operationId, _self.operation_id
        key :tags, _self.all_tags

        response 200 do
          key :description, 'API Response'
          schema do
            key :'$ref', _self.response_schema_id
          end
        end

        _self.util.jsonapi_sorting(self)
        _self.util.jsonapi_pagination(self)

        _self.util.each_filter(_self.resource) do |filter_label|
          _self.util.jsonapi_filter(self, filter_label)
        end

        _self.each_stat do |stat_name, calculations|
          _self.util.jsonapi_stat(self, stat_name, calculations)
        end

        _self.util.jsonapi_fields(self, _self.jsonapi_type)

        if _self.has_extra_fields?
          _self.util.jsonapi_extra_fields(self, _self.resource)
        end

        if _self.has_sideloads?
          _self.util.jsonapi_includes(self)

          _self.each_association do |association_name, association_resource|
            _self.util.jsonapi_fields(self, association_resource.config[:type])

            if association_resource.config[:extra_fields].keys.length > 0
              _self.util.jsonapi_extra_fields(self, association_resource)
            end

            _self.util.each_filter(association_resource, association_name) do |filter_label|
              _self.util.jsonapi_filter(self, filter_label)
            end
          end
        end
      end
    end
  end
end
