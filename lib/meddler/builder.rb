class Meddler
  class Builder

    attr_reader :app, :target

    def initialize(endpoint, &block)
      @target = Rack::Builder.new{}
      instance_eval(&block)
      @app = Meddler.new(endpoint, @on_request, @on_response, @before, @after, @target, @run_endpoint)
    end
    
    def method_missing(method, *args, &block)
      if method == :run
        @run_endpoint = args.first
      else
        target.send(method, *args, &block)
      end
    end
    
    def add_to_on_request
      (@on_request ||= []) << yield
    end
    
    def add_to_on_response
      (@on_response ||= []) << yield
    end
    
    def on_request(&block)
      add_to_on_request { block }
    end
      
    def on_response(&block)
      add_to_on_response { block }
    end
      
    def on_status(status)
      add_to_on_response { proc{|response| status === response.status } }
    end
      
    def on_path_info(path_info)
      add_to_on_request { proc{|request| path_info === request.path_info } }
    end
      
    def on_xhr?(invert = false)
      add_to_on_request { proc{|request| invert ^ request.xhr? } }
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
      app.call(env)
    end

  end
end