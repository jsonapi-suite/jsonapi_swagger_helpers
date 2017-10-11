require 'pp'
require 'net/http'

def get_local_swagger(path)
  session = ActionDispatch::Integration::Session.new(Rails.application)
  session.get path
  session.response.body
end

def get_remote_swagger(path)
  uri = URI(path)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true if uri.scheme == 'https'
  req = Net::HTTP::Get.new(uri)
  req['Authorization'] = "Token token=\"#{ENV['JSONAPI_TOKEN']}\""
  res = http.request(req)
  res.body
end

desc <<-DESC
Compare a local swagger.json to a remote swagger.json

Usage: swagger_diff[namespace,remote_host]

Example swagger_diff["api","http://myapp.com"]

If your app relies on JSON Web Tokens, you can set JSONAPI_TOKEN for authentication
DESC
task :swagger_diff, [:namespace, :remote_host] => [:environment] do |_, args|
  begin
    require 'swagger/diff'
  rescue LoadError
    raise 'You must install the swagger-diff gem to use the swagger_diff rake task'
  end

  remote_host = args[:remote_host] || 'http://localhost:3001'
  namespace   = args[:namespace]   || 'api'

  old  = get_remote_swagger("#{remote_host}/#{namespace}/swagger.json")
  new  = get_local_swagger("/#{namespace}/swagger.json")
  diff = Swagger::Diff::Diff.new(old, new)

  if diff.compatible?
    puts 'No backwards incompatibilities found!'
  else
    puts "Found backwards incompatibilities!\n\n"
    pp diff.incompatibilities.inspect
    exit(1)
  end
end
