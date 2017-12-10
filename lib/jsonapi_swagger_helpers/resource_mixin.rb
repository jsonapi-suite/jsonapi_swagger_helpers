module JsonapiSwaggerHelpers
  module ResourceMixin

    def jsonapi_resource(base_path,
                         tags: [],
                         descriptions: {},
                         only: [],
                         except: [],
                         singular: false)
      self.resources << {
        base_path: base_path,
        tags: tags,
        descriptions: descriptions,
        only: only,
        except: except,
        singular: singular
      }
    end

    def load_resource(config)
      base_path = config[:base_path]
      tags = config[:tags]
      descriptions = config[:descriptions]
      only = config[:only]
      except = config[:except]
      singular = config[:singular]

      actions = %i[index show create update destroy]
      actions.select! { |a| only.include?(a) } unless only.empty?
      actions.reject! { |a| except.include?(a) } unless except.empty?

      prefix     = @swagger_root_node.data[:basePath]
      full_path  = [prefix, base_path].join('/').gsub('//', '/')
      controller = JsonapiSwaggerHelpers::Util.controller_for(full_path)

      actions.each do |action|
        next unless controller.action_methods.include?(action.to_s)
        path = if !singular && %i[show update destroy].include?(action)
                 "#{base_path}/{id}"
               else
                 base_path
               end
        swagger_path path do
          action_class_name = "#{action.to_s.camelize}Action"
          action_class = JsonapiSwaggerHelpers.const_get(action_class_name)
          action_object = action_class.new \
            self, controller, tags: tags, description: descriptions[action],
                              singular: singular
          action_object.generate
        end
      end
    end
  end
end
