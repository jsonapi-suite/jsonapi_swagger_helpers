class JsonapiSwaggerHelpers::PayloadDefinition
  attr_reader :payload

  # Given a spec payload like:
  #
  # key(:name, String)
  #
  # Return the corresponding swagger type, ie :string
  # If a key has multiple types, we'll pick the first swagger type that matches:
  #
  # key(:total, [String, Integer]) => :string
  def self.swagger_type_for(payload_name, attribute, type)
    types = Array(type)
    return :string if types.empty?

    type_mapping.each_pair do |swagger_type, klasses|
      if types.any? { |t| klasses.include?(t) }
        return swagger_type
      end
    end

    raise JsonapiSwaggerHelpers::Errors::TypeNotFound
      .new(payload_name, attribute)
  end

  def self.type_mapping
    JsonapiSwaggerHelpers.config.type_mapping
  end

  def initialize(payload)
    @payload = payload
  end

  def context
    JsonapiSwaggerHelpers.docs_controller
  end

  def jsonapi_type
    payload.type
  end

  def generate
    _self = self

    context.send(:swagger_schema, payload.name) do
      payload = _self.payload

      payload.keys.each_pair do |attribute, config|
        property attribute do
          type = _self.class.swagger_type_for(payload.name, attribute, config[:type])
          key :type, type
          key :description, config[:description]
        end
      end
    end
  end
end
