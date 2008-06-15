require File.dirname(__FILE__) + '/../test_helper'
require 'notify_controller'
require 'yaml'

# Re-raise errors caught by the controller.
class NotifyController; def rescue_action(e) raise e end; end

class NotifyControllerTest < Test::Unit::TestCase
  fixtures :runs
  
  def setup
    @controller = NotifyController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_notify
    # TODO:  haven't yet figured out how to test this
#    post :index, :params => YAML.dump( { :project => 'foo', :build => 'bar', :revision => 1 } )
#    assert_response :success
  end
end
