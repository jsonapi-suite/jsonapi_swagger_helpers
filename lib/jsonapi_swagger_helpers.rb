require 'swagger/blocks'
require "jsonapi_spec_helpers"
require "jsonapi_swagger_helpers/errors"
require "jsonapi_swagger_helpers/configuration"
require "jsonapi_swagger_helpers/payload_definition"
require "jsonapi_swagger_helpers/util"
require "jsonapi_swagger_helpers/readable"
require "jsonapi_swagger_helpers/writeable"
require "jsonapi_swagger_helpers/index_action"
require "jsonapi_swagger_helpers/show_action"
require "jsonapi_swagger_helpers/create_action"
require "jsonapi_swagger_helpers/update_action"
require "jsonapi_swagger_helpers/destroy_action"
require "jsonapi_swagger_helpers/resource_mixin"
require "jsonapi_swagger_helpers/docs_controller_mixin"

require "jsonapi_swagger_helpers/railtie" if defined?(Rails)

module JsonapiSwaggerHelpers
  def self.configure
    yield config
  end

  def self.config
    @config ||= Configuration.new
  end

  def self.docs_controller
    @docs_controller ||= ::DocsController
  end

  def self.docs_controller=(controller)
    @docs_controller = controller
  end
end

Swagger::Blocks::OperationNode.prepend(JsonapiSwaggerHelpers)
