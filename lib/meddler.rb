require 'rack'

$: << File.dirname(__FILE__)
require 'meddler/builder'

class Meddler

  def initialize(app, before_rule, after_rule, wrapped_app)
    wrapped_app.run(PostInterceptor.new(app, after_rule))
    @app = PreInterceptor.new(wrapped_app.to_app, app, before_rule)
  end
  
  def call(env)
    response = catch(:skipped_middleware) do
      @app.call(env)
    end
    response
  end
  

  class PostInterceptor
    def initialize(app, rule = nil)
      @app = app
      @rule = rule
    end
    
    def call(env)
      response = @app.call(env)
      if @rule.nil? || @rule.call(Rack::Response.new(response))
        response
      else
        throw :skipped_middleware, response
      end
    end

  end
  
  class PreInterceptor
    attr_accessor :skip_app
    
    def initialize(app, skip_app, rule = nil)
      @app = app
      @skip_app = skip_app
      @rule = rule
    end
    
    def call(env)
      response = @rule.nil? || @rule.call(Rack::Request.new(env)) ? @app.call(env) : @skip_app.call(env)
    end
  end
  
end
