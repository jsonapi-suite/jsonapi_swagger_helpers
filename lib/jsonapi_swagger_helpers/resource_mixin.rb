module JsonapiSwaggerHelpers
  module ResourceMixin

    def jsonapi_resource(base_path, tags: [], descriptions: {}, only: [], except: [])
      actions   = [:index, :show, :create, :update, :destroy]

      unless only.empty?
        actions.select! { |a| only.include?(a) }
      end

      unless except.empty?
        actions.reject! { |a| except.include?(a) }
      end

      prefix     = @swagger_root_node.data[:basePath]
      full_path  = [prefix, base_path].join('/').gsub('//', '/')
      controller = controller_for(full_path)

      if [:create, :index].any? { |a| actions.include?(a) }
        swagger_path base_path do
          if actions.include?(:index)
            operation :get do
              key :tags, tags
              key :description, descriptions[:index]
              jsonapi_index(controller)
            end
          end

          if actions.include?(:create)
            operation :post do
              key :tags, tags
              key :description, descriptions[:create]
              strong_resource(controller, :create)
            end
          end
        end
      end

      if [:show, :update, :destroy].any? { |a| actions.include?(a) }
        swagger_path "#{base_path}/{id}" do
          if actions.include?(:show)
            operation :get do
              key :tags, tags
              key :description, descriptions[:show]
              jsonapi_show(controller)
            end
          end

          if actions.include?(:update)
            operation :put do
              key :tags, tags
              key :description, descriptions[:update]
              id_in_url
              strong_resource(controller, :update)
            end
          end

          if actions.include?(:destroy)
            operation :delete do
              key :tags, tags
              key :description, descriptions[:destroy]
              id_in_url
            end
          end
        end
      end
    end

    def controller_for(path)
      path = path.sub('{id}', '1')
      route = Rails.application.routes.recognize_path(path)
      "#{route[:controller]}_controller".classify.constantize
    end

  end
end
