module JsonapiSwaggerHelpers
  class SchemaHelpers
    def self.attributes_schema
      lambda do |attributes|
        property :attributes do
          key :type, :object

          attributes.each_pair do |name, attr_type|
            property name do
              key :name, name
              key :type, attr_type
            end
          end
        end
      end
    end

    def self.relationships_schema
      lambda do |relationships|
        property :relationships do
          key :type, :object

          relationships.each_pair do |relation_name, opts|
            property relation_name do
              property :data do
                if opts[:array]
                  key :type, :array
                  items do
                    if opts[:id]
                      property :id do
                        key :type, :string
                      end
                    end

                    property :type do
                      key :type, :string
                      key :required, true
                      key :enum, [opts[:jsonapi_type]]
                    end

                    if opts[:attributes]
                      instance_exec(opts[:attributes], &SchemaHelpers.attributes_schema)
                    end

                    if opts[:relationships]
                      instance_exec(opts[:relationships], &SchemaHelpers.relationships_schema)
                    end
                  end
                else
                  if opts[:id]
                    property :id do
                      key :type, :string
                    end
                  end

                  property :type do
                    key :type, :string
                    key :required, true
                    key :enum, [opts[:jsonapi_type]]
                  end

                  if opts[:attributes]
                    instance_exec(opts[:attributes], &SchemaHelpers.attributes_schema)
                  end

                  if opts[:relationships]
                    instance_exec(opts[:relationships], &SchemaHelpers.relationships_schema)
                  end
                end
              end
            end
          end
        end
      end
    end

  end
end
