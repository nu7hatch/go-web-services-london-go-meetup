# -*- ruby -*- 
require 'bundler/setup'

class Rack::ExtStatic < Rack::Static
  def call(env)
    resp = super(env)
    if resp[0] == 404
      static = Rack::Static.new(proc { [404, "", ""] }, :root => 'static', :urls => [""])
      resp = static.call(env)
    end
    if resp[0] == 404
      path_info = env['PATH_INFO']
      env['PATH_INFO'] += @index if path_info =~ /\/$/
      resp = super(env)
    end
    resp
  end
end

use Rack::ExtStatic, {
  :root  => '.',
  :index => 'index.html',
  :urls  => [""],
}

run lambda {
  [404, {"Content-Type"   => "text/plain"}, "Error 404"]
}
