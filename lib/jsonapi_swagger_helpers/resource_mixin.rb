module JsonapiSwaggerHelpers
  module ResourceMixin

    def jsonapi_resource(base_path,
                         tags: [],
                         descriptions: {},
                         only: [],
                         except: [])
      self.resources << {
        base_path: base_path,
        tags: tags,
        descriptions: descriptions,
        only: only,
        except: except
      }
    end

    def load_resource(config)
      base_path = config[:base_path]
      tags = config[:tags]
      descriptions = config[:descriptions]
      only = config[:only]
      except = config[:only]

      actions = [:index, :show, :create, :update, :destroy]
      actions.select! { |a| only.include?(a) } unless only.empty?
      actions.reject! { |a| except.include?(a) } unless except.empty?

      prefix     = @swagger_root_node.data[:basePath]
      full_path  = [prefix, base_path].join('/').gsub('//', '/')
      controller = JsonapiSwaggerHelpers::Util.controller_for(full_path)

      ctx = self
      if [:create, :index].any? { |a| actions.include?(a) }
        swagger_path base_path do
          if actions.include?(:index) && controller.action_methods.include?('index')
            index_action = JsonapiSwaggerHelpers::IndexAction.new \
              self, controller, tags: tags, description: descriptions[:index]
            index_action.generate
          end

          if actions.include?(:create) && controller.action_methods.include?('create')
            create_action = JsonapiSwaggerHelpers::CreateAction.new \
              self, controller, tags: tags, description: descriptions[:create]
            create_action.generate
          end
        end
      end

      if [:show, :update, :destroy].any? { |a| actions.include?(a) }
        ctx = self
        swagger_path "#{base_path}/{id}" do
          if actions.include?(:show) && controller.action_methods.include?('show')
            show_action = JsonapiSwaggerHelpers::ShowAction.new \
              self, controller, tags: tags, description: descriptions[:show]
            show_action.generate
          end

          if actions.include?(:update) && controller.action_methods.include?('update')
            update_action = JsonapiSwaggerHelpers::UpdateAction.new \
              self, controller, tags: tags, description: descriptions[:update]
            update_action.generate
          end

          if actions.include?(:destroy) && controller.action_methods.include?('destroy')
            destroy_action = JsonapiSwaggerHelpers::DestroyAction.new \
              self, controller, tags: tags, description: descriptions[:destroy]
            destroy_action.generate
          end
        end
      end
    end
  end
end
