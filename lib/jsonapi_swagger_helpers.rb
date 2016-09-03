require 'swagger/blocks'
require "jsonapi_swagger_helpers/version"
require "jsonapi_swagger_helpers/schema_helpers"
require "jsonapi_swagger_helpers/strong_resource_mixin"
require "jsonapi_swagger_helpers/resource_mixin"
require "jsonapi_swagger_helpers/docs_controller_mixin"

module JsonapiSwaggerHelpers
  def self.prepended(klass)
    klass.send(:include, StrongResourceMixin)
  end

  def self.docs_controller
    @docs_controller ||= ::DocsController
  end

  def self.docs_controller=(controller)
    @docs_controller = controller
  end

  def jsonapi_link
    "<br/><p><a href='http://jsonapi.org'>JSONAPI-compliant</a> endpoint.</p><br />"
  end

  def validation_messages(messages)
    string = "<p><b>Validations:</b><ul>"
    messages.each do |message|
      string << "<li>#{message}</li>"
    end
    string << "</ul></p>"
  end

  def jsonapi_index(controller)
    jsonapi_includes(controller, :index)
    jsonapi_filters(controller)
    jsonapi_pagination
    jsonapi_sorting
  end

  def jsonapi_show(controller)
    id_in_url
    jsonapi_includes(controller, :show)
  end

  def id_in_url
    parameter do
      key :name, :id
      key :in, :path
      key :type, :string
      key :required, true
      key :description, 'record id'
    end
  end

  def jsonapi_filters(controller)
    filter_names = []
    controller._jsonapi_config._filters.each_pair do |name, opts|
      filter_names << name
    end

    filter_names.each do |filter_name|
      parameter do
        key :name, "filter[#{filter_name}]"
        key :in, :query
        key :type, :string
        key :required, false
        key :description, "<a href='http://jsonapi.org/format/#fetching-filtering'>JSONAPI filter</a>"

        items do
          key :model, :string
        end
      end
    end
  end

  def jsonapi_pagination
    parameter do
      key :name, "page[size]"
      key :in, :query
      key :type, :string
      key :required, false
      key :description, "<a href='http://jsonapi.org/format/#fetching-pagination'>JSONAPI page size</a>"
    end

    parameter do
      key :name, "page[number]"
      key :in, :query
      key :type, :string
      key :required, false
      key :description, "<a href='http://jsonapi.org/format/#fetching-pagination'>JSONAPI page number</a>"
    end
  end

  def jsonapi_sorting
    parameter do
      key :name, :sort
      key :in, :query
      key :type, :string
      key :required, false
      key :description, "<a href='http://jsonapi.org/format/#fetching-sorting'>JSONAPI sort</a>"
    end
  end

  def jsonapi_includes(controller, action)
    includes = controller._jsonapi_config._includes[:whitelist]

    if includes
      directive = includes[action]
      includes  = directive.to_string

      parameter do
        key :name, :include
        key :in, :query
        key :type, :string
        key :required, false
        key :description, "<a href='http://jsonapi.org/format/#fetching-includes'>JSONAPI includes</a>: \"#{includes}\""
      end
    end
  end
end

Swagger::Blocks::OperationNode.prepend(JsonapiSwaggerHelpers)
