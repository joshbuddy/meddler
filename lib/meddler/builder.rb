class Meddler
  class Builder

    def initialize(app, &block)
      @app = app
      @target = Rack::Builder.new{}
      instance_eval(&block)
      @meddler = Meddler.new(@app, @on_request, @on_response, @before, @after, @target)
    end
    
    def method_missing(method, *args, &block)
      @target.send(method, *args, &block)
    end
    
    def on_request(&block)
      @on_request ||= []
      @on_request << block
    end
      
    def on_response(&block)
      @on_response ||= []
      @on_response << block
    end
      
    def before(&block)
      @before ||= []
      @before << block
    end
    
    def after(&block)
      @after ||= []
      @after << block
    end
    
    def call(env)
      @meddler.call(env)
    end

  end
end