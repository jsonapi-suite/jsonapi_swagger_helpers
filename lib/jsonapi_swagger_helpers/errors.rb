module JsonapiSwaggerHelpers
  module Errors
    class TypeNotFound < StandardError
      def initialize(payload_name, attribute)
        @payload_name = payload_name
        @attribute = attribute
      end

      def message
        <<-STR
Could not find type mapping for payload "#{@payload_name}", key "#{@attribute}".

To add a custom mapping:

JsonapiSwaggerHelpers.configure do |c|
  c.type_mapping[:string] << MyCustomType
end
        STR
      end
    end
  end
end
