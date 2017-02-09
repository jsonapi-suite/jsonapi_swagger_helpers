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
    jsonapi_filters(controller, :index)
    jsonapi_stats(controller)
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

  private

  def all_resources(resource, include_directive, memo = {})
    resource.sideloading.sideloads.each_pair do |name, sideload|
      next if memo[name] || !include_directive.key?(name)

      memo[name] = sideload.resource.class
      all_resources(sideload.resource.class, include_directive[name], memo)
    end
    memo
  end

  def jsonapi_filters(controller, action_name)
    filters = {}
    resource_class = controller._jsonapi_compliable
    directive = includes_for_action(controller, action_name)
    resources = all_resources(resource_class, directive)
    resources[:base] = resource_class

    resources.each_pair do |name, klass|
      klass.config[:filters].each_pair do |filter_name, opts|
        filters[name] ||= []
        filters[name] << filter_name
      end
    end

    filters.each_pair do |association_name, filter_names|
      filter_names.each do |name|
        filter_name = association_name == :base ? "filter[#{name}]" : "filter[#{association_name}][#{name}]"

        parameter do
          key :name, filter_name
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
  end

  def jsonapi_stats(controller)
    controller._jsonapi_compliable.config[:stats].each_pair do |stat_name, opts|
      calculations = opts.calculations.keys - [:keys]
      calculations = calculations.join('<br/>')
      parameter do
        key :name, "stats[#{stat_name}]"
        key :in, :query
        key :type, :string
        key :required, false
        key :description, "<a href='http://jsonapi.org/format/#document-meta'>JSONAPI meta data</a><br/> #{calculations}"

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

  def includes_for_action(controller, action)
    resource_class = controller._jsonapi_compliable
    includes       = resource_class.sideloading.to_hash[:base]
    whitelist      = resource_class.config[:sideload_whitelist]

    if whitelist && whitelist[action]
      includes = JsonapiCompliable::Util::IncludeParams.scrub(includes, whitelist[action])
    end

    JSONAPI::IncludeDirective.new(includes)
  end

  def jsonapi_includes(controller, action)
    if directive = includes_for_action(controller, action)
      includes = directive.to_string.split(",").sort.join(",<br/>")

      parameter do
        key :name, :include
        key :in, :query
        key :type, :string
        key :required, false
        key :description, "<a href='http://jsonapi.org/format/#fetching-includes'>JSONAPI includes</a>: <br/> #{includes}"
      end
    end
  end
end

Swagger::Blocks::OperationNode.prepend(JsonapiSwaggerHelpers)
