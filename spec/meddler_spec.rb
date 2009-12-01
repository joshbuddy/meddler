require 'rack'

class TestMiddleware
  attr_reader :state
  
  @@last_instance = nil
  
  def self.last_instance
    @@last_instance
  end
  
  def self.reset_last_instance!
    @last_instance = nil
  end

  def initialize(app)
    @@last_instance = self
    @state = :initial
    @app = app
  end

  def call(env)
    @state = :pre
    response = @app.call(env)
    @state = :post
    response
  end
end

describe "pre" do
  
  before(:each) do
    TestMiddleware.reset_last_instance!
  end
  
  it "should run normally" do
    @builder = Meddler::Builder.new(proc {|env| [200, {'Content-type' => 'text/html', 'Content-length' => '5'}, ['hello']]}) do
      use TestMiddleware
    end
    @builder.call(Rack::MockRequest.env_for('/'))
    TestMiddleware.last_instance.state.should == :post
  end

  it "should stop on_request" do
    @builder = Meddler::Builder.new(proc {|env| [200, {'Content-type' => 'text/html', 'Content-length' => '5'}, ['hello']]}) do
      on_request{|request| request.post? }
      use TestMiddleware
    end
    @builder.call(Rack::MockRequest.env_for('/'))
    TestMiddleware.last_instance.state.should == :initial
  end

  it "should stop on_repsonse" do
    @builder = Meddler::Builder.new(proc {|env| [200, {'Content-type' => 'text/html', 'Content-length' => '5'}, ['hello']]}) do
      on_response{|response| response.status == 404 }
      use TestMiddleware
    end
    @builder.call(Rack::MockRequest.env_for('/'))
    TestMiddleware.last_instance.state.should == :pre
  end

  it "should call before" do
    before_called = false
    @builder = Meddler::Builder.new(proc {|env| [200, {'Content-type' => 'text/html', 'Content-length' => '5'}, ['hello']]}) do
      before{|response| before_called = true}
      use TestMiddleware
    end
    @builder.call(Rack::MockRequest.env_for('/'))
    before_called.should be_true
  end

  it "should call after" do
    after_called = false
    @builder = Meddler::Builder.new(proc {|env| [200, {'Content-type' => 'text/html', 'Content-length' => '5'}, ['hello']]}) do
      after{|response| after_called = true}
      use TestMiddleware
    end
    @builder.call(Rack::MockRequest.env_for('/'))
    after_called.should be_true
  end

end