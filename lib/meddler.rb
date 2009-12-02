require 'rack'

$: << File.dirname(__FILE__)
require 'meddler/builder'

class Meddler

  attr_reader :original_app, :app

  def initialize(original_app, on_request, on_response, before, after, wrapped_app, skip_app = original_app)
    @original_app, @skip_app = original_app, skip_app
    wrapped_app.run(PostInterceptor.new(original_app, on_response, after, signal))
    @app = PreInterceptor.new(wrapped_app.to_app, skip_app, on_request, before)
  end
  
  def signal
    self.object_id.to_s.to_sym
  end
  
  def call(env)
    response = catch(signal) do
      app.call(env)
    end

    if response.length == 4 && response.last == signal
      response.pop
      if @skip_app != @original_app
        @skip_app.call(env)
      else
       response
      end
    else
      response
    end
  end
  

  class PostInterceptor
    attr_reader :app, :rules, :filters, :signal
    def initialize(app, rules, filters, signal)
      @app = app
      @rules = rules
      @filters = filters
      @signal = signal
    end
    
    def call(env)
      raw_response = app.call(env)
      response = Rack::Response.new(raw_response[2], raw_response[0], raw_response[1])
      if rules.nil? || rules.all?{|r| r.call(response)}
        filters && filters.each{|f| f.call(response)}
        [response.status, response.headers, response.body]
      else
        throw signal, [response.status, response.headers, response.body, signal]
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
        app.call(request.env)
      else
        skip_app.call(request.env)
      end
    end
  end
  
end
