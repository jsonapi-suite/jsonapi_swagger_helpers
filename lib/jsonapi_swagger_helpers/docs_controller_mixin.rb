module JsonapiSwaggerHelpers
  module DocsControllerMixin
    def self.included(klass)
      # Save our controller so we can execute Swagger::Blocks code against it
      JsonapiSwaggerHelpers.docs_controller = klass

      # Add glue code
      klass.send(:include, Swagger::Blocks)
      klass.extend(ResourceMixin) # jsonapi_resource DSL
      klass.extend(ClassMethods) # for predefining payloads

      # Predefine swagger definitions for later reference
      #   * spec payloads define outputs
      #   * strong resources define inputs
      klass.register_payload_definitions!
    end

    module ClassMethods
      def register_payload_definitions!
        JsonapiSpecHelpers.load_payloads!
        JsonapiSpecHelpers::Payload.registry.each_pair do |payload_name, payload|
          JsonapiSwaggerHelpers::PayloadDefinition.new(payload).generate
        end
      end
    end

    # Give Swagger::Blocks what it wants
    def index
      render json: Swagger::Blocks.build_root_json([self.class])
    end
  end
end
