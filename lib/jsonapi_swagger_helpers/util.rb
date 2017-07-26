module JsonapiSwaggerHelpers
  class Util
    def self.controller_for(path)
      path = path.sub('{id}', '1')
      route = find_route(path)

      if route
        "#{route[:controller]}_controller".classify.constantize
      else
        Rails.logger.error("JsonapiSwaggerHelpers: No controller found for #{path}!") unless route
      end
    end

    def self.find_route(path)
      route = rails_route(path, 'GET')
      route ||= rails_route(path, 'POST')
      route ||= rails_route(path, 'PUT')
      route ||= rails_route(path, 'DELETE')
      route
    end

    def self.rails_route(path, method)
      Rails.application.routes.recognize_path(path, method: method) rescue nil
    end

    def self.sideload_label(include_directive)
      sideloads = include_directive.to_string.split(",").sort.join(",<br/>")

      <<-HTML
  <label>
    Possible sideloads:
    <span class="possible-sideloads">#{sideloads}</span>
  </label>
      HTML
    end

    def self.each_filter(resource, association_name = nil)
      resource.config[:filters].each_pair do |filter_name, opts|
        if association_name
          yield "filter[#{association_name}][#{filter_name}]"
        else
          yield "filter[#{filter_name}]"
        end
      end
    end

    def self.all_resources(resource, include_directive, memo = {})
      resource.sideloading.sideloads.each_pair do |name, sideload|
        next if memo[name] || !include_directive.key?(name)

        memo[name] = sideload.resource.class
        all_resources(sideload.resource.class, include_directive[name], memo)
      end
      memo
    end

    def self.include_directive_for(controller, action)
      resource_class = controller._jsonapi_compliable
      includes       = resource_class.sideloading.to_hash[:base]
      whitelist      = resource_class.config[:sideload_whitelist]

      if whitelist && whitelist[action]
        includes = JsonapiCompliable::Util::IncludeParams
          .scrub(includes, whitelist[action])
      end

      JSONAPI::IncludeDirective.new(includes)
    end

    def self.payloads_for(resource, include_hash)
      [].tap do |payloads|
        payloads << JsonapiSpecHelpers::Payload.by_type(resource.config[:type])

        include_hash.each_pair do |name, nested|
          sideload = resource.sideloading.sideloads[name]

          if sideload.polymorphic?
            sideload.polymorphic_groups.each_pair do |type, sl|
              payloads << payloads_for(sl.resource_class, nested)
            end
          else
            sideload_resource = sideload.resource_class
            payloads << payloads_for(sideload_resource, nested)
          end
        end
      end.flatten.uniq(&:name)
    end

    def self.payload_tags_for(resource, include_hash)
      payloads_for(resource, include_hash).map { |p| "payload-#{p.name}" }
    end

    def self.jsonapi_filter(node, label)
      node.parameter do
        key :description, '<a href="http://jsonapi.org/format/#fetching-filtering">JSONAPI Filter</a>'
        key :name, label
        key :in, :query
        key :type, :string
        key :required, false
      end
    end

    def self.jsonapi_sorting(node)
      node.parameter do
        key :description, '<a href="http://jsonapi.org/format/#fetching-sorting">JSONAPI Sorting</a>'
        key :name, :sort
        key :in, :query
        key :type, :string
        key :required, false
      end
    end

    def self.jsonapi_pagination(node)
      node.parameter do
        key :description, '<a href="http://jsonapi.org/format/#fetching-pagination">JSONAPI Page Size</a>'
        key :name, "page[size]"
        key :in, :query
        key :type, :string
        key :required, false
      end

      node.parameter do
        key :description, '<a href="http://jsonapi.org/format/#fetching-pagination">JSONAPI Page Number</a>'
        key :name, "page[number]"
        key :in, :query
        key :type, :string
        key :required, false
      end
    end

    def self.jsonapi_stat(node, name, calculations)
      node.parameter do
        key :name, "stats[#{name}]"
        key :description, "<a href=\"https://jsonapi-suite.github.io/jsonapi_suite/how-to-return-statistics\">JSONAPI Stats</a><br /><b>Possible Calculations:</b> #{calculations}"
        key :in, :query
        key :type, :string
        key :required, false
      end
    end

    def self.jsonapi_includes(node)
      node.parameter do
        key :description, '<a href="http://jsonapi.org/format/#fetching-includes">JSONAPI Includes</a>'
        key :name, :include
        key :in, :query
        key :type, :string
        key :required, false
      end
    end

    def self.jsonapi_fields(node, jsonapi_type)
      node.parameter do
        key :description, '<a href="http://jsonapi.org/format/#fetching-sparse-fieldsets">JSONAPI Sparse Fieldset</a>'
        key :name, "fields[#{jsonapi_type}]"
        key :in, :query
        key :type, :string
        key :required, false
      end
    end

    def self.jsonapi_extra_fields(node, resource)
      jsonapi_type = resource.config[:type]

      extra_field_names = resource.config[:extra_fields].keys.join(',')
      node.parameter do
        key :description, "<a href=\"https://jsonapi-suite.github.io/jsonapi_suite/how-to-conditionally-render-fields\">JSONAPI Extra Fields</a><br /><b>Possible Fields:</b> #{extra_field_names}"
        key :name, "extra_fields[#{jsonapi_type}]"
        key :in, :query
        key :type, :string
        key :required, false
      end
    end

    def self.id_in_url(node)
      node.parameter do
        key :name, :id
        key :in, :path
        key :type, :string
        key :required, true
        key :description, 'record id'
      end
    end
  end
end
