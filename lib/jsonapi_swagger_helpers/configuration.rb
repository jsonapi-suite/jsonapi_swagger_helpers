module JsonapiSwaggerHelpers
  class Configuration
    def type_mapping
      @type_mapping ||= {
        string: [String],
        integer: [Integer, Bignum],
        float: [Float],
        boolean: [TrueClass, FalseClass],
        object: [Hash]
      }
    end
  end
end
