class Meddler
  class Builder

    def initialize(app, rules = nil, &block)
      @app = app
      @target = Rack::Builder.new(&block)
      @meddler = Meddler.new(@app, rules && rules[:on_request], rules && rules[:on_response], @target)
    end

    def call(env)
      @meddler.call(env)
    end

  end
end