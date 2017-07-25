require 'pp'
begin
  require 'swagger/diff'
rescue LoadError
  puts "You must install the swagger-diff gem to use the swagger_diff rake task"
  exit(1)
end

def get_swagger(path)
  token = ENV['JSONAPI_TOKEN']
  session = ActionDispatch::Integration::Session.new(Rails.application)
  session.get path, headers: {
    'Authorization' => "Token token=\"#{token}\""
  }
  session.response.body
end

desc <<-DESC
Compare a local swagger.json to a remote swagger.json

Usage: swagger_diff[namespace,local_host,remote_host]

Example swagger_diff["api","http://localhost:3000","http://myapp.com"]

If your app relies on JSON Web Tokens, you can set JSONAPI_TOKEN for authentication
DESC
task :swagger_diff, [:namespace, :local_host, :remote_host] => [:environment] do |_, args|
  local_host  = args[:local_host]  || 'http://localhost:3000'
  remote_host = args[:remote_host] || 'http://localhost:3000'
  namespace   = args[:namespace]   || 'api'

  old  = get_swagger("#{remote_host}/#{namespace}/swagger.json")
  new  = get_swagger("#{local_host}/#{namespace}/swagger.json")
  diff = Swagger::Diff::Diff.new(old, new)

  if diff.compatible?
    puts 'No backwards incompatibilities found!'
  else
    puts "Found backwards incompatibilities!\n\n"
    pp JSON.parse(diff.incompatibilities)
    exit(1)
  end
end
