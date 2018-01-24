module JsonapiSwaggerHelpers
  class Configuration
    def type_mapping
      @type_mapping ||= {
        string: [String],
        integer: [Integer, Bignum],
        number: [Float],
        boolean: [TrueClass, FalseClass],
        object: [Hash],
        array: [Array]
      }
    end
  end
end
