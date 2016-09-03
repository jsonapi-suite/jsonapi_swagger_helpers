module JsonapiSwaggerHelpers
  module DocsControllerMixin
    def self.included(klass)
      klass.send(:include, Swagger::Blocks)
      klass.extend(ResourceMixin)
    end

    def index
      klasses = [self.class, JsonapiSwaggerHelpers::StrongResourceMixin::Schemas]
      render json: Swagger::Blocks.build_root_json(klasses)
    end
  end
end
