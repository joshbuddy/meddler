require 'rack'

$: << File.dirname(__FILE__)
require 'meddler/builder'

class Meddler

  def initialize(app, on_request, on_response, before, after, wrapped_app)
    wrapped_app.run(PostInterceptor.new(app, on_response, after))
    @app = PreInterceptor.new(wrapped_app.to_app, app, on_request, before)
  end
  
  def call(env)
    response = catch(:skipped_middleware) do
      @app.call(env)
    end
    response
  end
  

  class PostInterceptor
    attr_reader :app, :rules, :filters
    def initialize(app, rules, filters)
      @app = app
      @rules = rules
      @filters = filters
    end
    
    def call(env)
      raw_response = app.call(env)
      response = Rack::Response.new(raw_response[2], raw_response[0], raw_response[1])
      if rules.nil? || rules.all?{|r| r.call(response)}
        filters && filters.each{|f| f.call(response)}
        response.to_a
      else
        throw :skipped_middleware, response.to_a
      end
    end

  end

  class PreInterceptor
    attr_reader :app, :skip_app, :rules, :filters
    def initialize(app, skip_app, rules, filters)
      @app = app
      @skip_app = skip_app
      @rules = rules
      @filters = filters
    end

    def call(env)
      request = Rack::Request.new(env)
      if rules.nil? || rules.all?{|f| f.call(request)}
        filters && filters.each{|f| f.call(request)}
        app.call(env)
      else
        skip_app.call(env)
      end
    end
  end
  
end
