module MyGem
  class Railtie < Rails::Railtie
    rake_tasks do
      load 'tasks/swagger_diff.rake'
    end
  end
end
