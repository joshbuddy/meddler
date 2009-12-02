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

describe Meddler do
  
  before(:each) do
    TestMiddleware.reset_last_instance!
    @app = proc {|env| [200, {'Content-type' => 'text/html', 'Content-length' => '5'}, ['hello']]}
  end
  
  it "should run normally" do
    @builder = Meddler::Builder.new(@app) do
      use TestMiddleware
    end
    @builder.call(Rack::MockRequest.env_for('/')).last.should == ['hello']
    TestMiddleware.last_instance.state.should == :post
  end

  it "should stop on_request" do
    @builder = Meddler::Builder.new(@app) do
      on_request{|request| request.post? }
      use TestMiddleware
    end
    @builder.call(Rack::MockRequest.env_for('/')).last.should == ['hello']
    TestMiddleware.last_instance.state.should == :initial
  end

  it "should stop multiple on_request" do
    @builder = Meddler::Builder.new(@app) do
      on_request{|request| request.get? }
      on_request{|request| request.path_info == '/' }
      use TestMiddleware
    end
    @builder.call(Rack::MockRequest.env_for('/test')).last.should == ['hello']
    TestMiddleware.last_instance.state.should == :initial
  end

  it "should stop on_repsonse" do
    @builder = Meddler::Builder.new(@app) do
      on_response{|response| response.status == 404 }
      use TestMiddleware
    end
    @builder.call(Rack::MockRequest.env_for('/')).last.should == ['hello']
    TestMiddleware.last_instance.state.should == :pre
  end

  it "should stop on_status" do
    @builder = Meddler::Builder.new(@app) do
      on_status 300..500
      use TestMiddleware
    end
    @builder.call(Rack::MockRequest.env_for('/')).last.should == ['hello']
    TestMiddleware.last_instance.state.should == :pre
  end

  it "should stop on_path_info" do
    @builder = Meddler::Builder.new(@app) do
      on_path_info '/path'
      use TestMiddleware
    end
    @builder.call(Rack::MockRequest.env_for('/')).last.should == ['hello']
    TestMiddleware.last_instance.state.should == :initial
  end

  it "should stop on_xhr?" do
    @builder = Meddler::Builder.new(@app) do
      on_xhr?
      use TestMiddleware
    end
    @builder.call(Rack::MockRequest.env_for('/')).last.should == ['hello']
    TestMiddleware.last_instance.state.should == :initial
  end

  it "should stop multiple on_repsonse" do
    @builder = Meddler::Builder.new(@app) do
      on_response{|response| response.status == 200 }
      on_response{|response| response.length == 10 }
      use TestMiddleware
    end
    @builder.call(Rack::MockRequest.env_for('/')).last.should == ['hello']
    TestMiddleware.last_instance.state.should == :pre
  end

  it "should call before" do
    before_called = false
    @builder = Meddler::Builder.new(@app) do
      before{|response| before_called = true}
      use TestMiddleware
    end
    @builder.call(Rack::MockRequest.env_for('/')).last.should == ['hello']
    TestMiddleware.last_instance.state.should == :post
    before_called.should be_true
  end

  it "should call after" do
    after_called = false
    @builder = Meddler::Builder.new(@app) do
      after{|response| after_called = true}
      use TestMiddleware
    end
    @builder.call(Rack::MockRequest.env_for('/')).last.should == ['hello']
    TestMiddleware.last_instance.state.should == :post
    after_called.should be_true
  end

  it "should be able to act as an endpoint" do
    after_called = false
    @builder = Meddler::Builder.new(@app) do
      use TestMiddleware
      run proc {|env| [200, {'Content-type' => 'text/html', 'Content-length' => '10'}, ['hellohello']]}
    end
    @builder.call(Rack::MockRequest.env_for('/')).last.should == ['hellohello']
    TestMiddleware.last_instance.state.should == :post
  end

  it "should be able to act as an endpoint (which gets skipped)" do
    after_called = false
    @builder = Meddler::Builder.new(@app) do
      on_status 404
      use TestMiddleware
      run proc {|env| [200, {'Content-type' => 'text/html', 'Content-length' => '10'}, ['hellohello']]}
    end
    @builder.call(Rack::MockRequest.env_for('/')).last.should == ['hello']
    TestMiddleware.last_instance.state.should == :pre
  end

end