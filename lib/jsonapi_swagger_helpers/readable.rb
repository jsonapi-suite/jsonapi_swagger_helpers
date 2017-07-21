module JsonapiSwaggerHelpers::Readable
  def self.included(klass)
    klass.class_eval do
      attr_reader :node,
        :controller,
        :resource,
        :description,
        :tags
    end
  end

  def initialize(node, controller, description: nil, tags: [])
    @node = node
    @controller = controller
    @resource = controller._jsonapi_compliable
    @description = description || default_description
    @tags = tags
  end

  def default_description
    "#{action_name.capitalize} Action"
  end

  def operation_id
    "#{controller.name.gsub('::', '-')}-#{action_name}"
  end

  def util
    JsonapiSwaggerHelpers::Util
  end

  def include_directive
    util.include_directive_for(controller, action_name)
  end

  def has_sideloads?
    include_directive.keys.length > 0
  end

  def has_extra_fields?
    resource.config[:extra_fields].keys.length > 1
  end

  def full_description
    "#{description}<br /><br />#{util.sideload_label(include_directive)}"
  end

  def all_tags
    tags + payload_tags
  end

  def payload_tags
    util.payload_tags_for(resource, include_directive.to_hash)
  end

  def operation_id
    "#{controller.name.gsub('::', '-')}-#{action_name}"
  end

  def each_stat
    resource.config[:stats].each_pair do |stat_name, opts|
      calculations = opts.calculations.keys - [:keys]
      calculations = calculations.join(', ')

      yield stat_name, calculations
    end
  end

  def each_association
    resource_map = util.all_resources(resource, include_directive)
    resource_map.each_pair do |association_name, association_resource|
      yield association_name, association_resource
    end
  end

  def jsonapi_type
    resource.config[:type]
  end

  def generate
    raise 'override me'
  end
end
