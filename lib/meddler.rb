class Meddler

  attr_reader :middleware
  
  def initialize(app, before_rule, after_rule, middleware_class, *args, &blk)
    @app = PreInterceptor.new(middleware_class.new(PostInterceptor.new(app, after_rule), *args, &blk), app, before_rule)
  end
  
  def call(env)
    response = catch(:skipped_middleware) do
      @app.call(env)
    end
  end
  

  class PostInterceptor
    def initialize(app, rule = nil)
      @app = app
      @rule = rule
    end
    
    def call(env)
      response = @app.call(env)
      if @rule.nil? || @rule.call(response)
        response
      else
        throw :skipped_middleware
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
      response = @rule.nil? || @rule.call(env) ? @app.call(env) : @skip_app.call(env)
    end
  end
  
end
