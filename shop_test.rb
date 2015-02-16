ENV['RACK_ENV'] = 'test'

#Load environment variables from .env file...
require 'dotenv'
Dotenv.load('.env.test', '.env')

require './shop'
require 'test/unit'
require 'rack/test'

ENV['ENABLE_SMS'] = "NO"

class ShopTest < Test::Unit::TestCase
  include Rack::Test::Methods
  def setup

    Customer.all.destroy!
    Order.all.destroy!
  end

  def app
    Sinatra::Application
  end

  def test_it_should_wakeup
    get '/wakeup'
    assert last_response.ok?, "Expected 200 but got #{last_response.status}"
    assert_equal 'OK', last_response.body, "Wakeup Failed"
  end

  def test_it_should_render_dashboard
    get '/coffee-shop-bar-manager-thingy-do-dar'
    assert last_response.ok?, "Expected 200 but got #{last_response.status}"
    assert last_response.body.include?('SMS Coffee Shop'), "Body didn't include expected text: #{last_response.body}"
  end

  def test_respond_to_help_sms
    post '/order', {:Body => "help", :From => "+2"}
    assert last_response.ok?, "Expected 200 but got #{last_response.status}"
    assert last_response.body.include?("<Message>Oh dear. We're going to give you a call"), "Last response not as expected. #{last_response.body}"
  end

  def test_respond_to_valid_drink_sms
    post '/order', {:Body => "tea", :From => "+1"}
    assert last_response.ok?, "Expected 200 but got #{last_response.status}"
    assert last_response.body.include?('<Message>Thanks for ordering'), "Last Response not as expected. #{last_response.body}"
    assert_not_nil last_response.headers['x-order-id']
  end

  def test_invalid_order_is_rejected
    post '/order', {:Body => "banana", :From => "+7"}
    assert last_response.ok?, "Expected 200 but got #{last_response.status}"
    assert last_response.body.include?("<Message>Twilio's SMS Coffee Shop doesn't"), "Last Response not as expected. #{last_response.body}"
    assert_not_nil last_response.headers['x-order-id']
  end

  def test_reorder_invalid_drink_is_rejectd
    post '/order', {:Body => "tea", :From => "+6"}
    assert last_response.ok?, "Expected 200 but got #{last_response.status}"
    assert last_response.body.include?("<Message>Thanks for ordering a"), "Last Response not as expected. #{last_response.body}"
    post '/order', {:Body => "banana", :From => "+6"}
    assert last_response.ok?, "Expected 200 but got #{last_response.status}"
    assert last_response.body.include?("<Message>We're still making you a "), "Last Response not as expected. #{last_response.body}"
  end

  def test_reorder_valid_drink_is_rejectd
    post '/order', {:Body => "tea", :From => "+5"}
    assert last_response.ok?, "Expected 200 but got #{last_response.status}"
    assert last_response.body.include?("<Message>Thanks for ordering a"), "Last Response not as expected. #{last_response.body}"
    post '/order', {:Body => "tea", :From => "+5"}
    assert last_response.ok?, "Expected 200 but got #{last_response.status}"
    assert last_response.body.include?("<Message>We're still making you a "), "Last Response not as expected. #{last_response.body}"
  end

  def test_fulfillment_works
    post '/order', {:Body => "tea", :From => "+3"}
    assert last_response.ok?, "Expected 200 but got #{last_response.status}"
    assert last_response.body.include?('<Message>Thanks for ordering'), "Last Response not as expected. #{last_response.body}"
    order_id = last_response.headers['x-order-id']

    post '/forfill/'+order_id.to_s
    assert last_response.ok?, "Expected 200 on fulfillment but got #{last_response.status}"
  end

  def test_cancellation_works
    post '/order', {:Body => "tea", :From => "+4"}
    assert last_response.ok?, "Expected 200 but got #{last_response.status}"
    assert last_response.body.include?('<Message>Thanks for ordering'), "Last Response not as expected. #{last_response.body}"
    order_id = last_response.headers['x-order-id']

    post '/cancel/'+order_id.to_s
    assert last_response.ok?, "Expected 200 on fulfillment but got #{last_response.status}"
  end

  def test_cancel_invalid_string_order_works
    post '/cancel/fredsentme'
    assert !last_response.ok?, "Platform errored which it should not have done. #{last_response.status}"
  end

  def test_cancel_invalid_numeric_order_works
    post '/cancel/12345678987'
    assert !last_response.ok?, "Platform errored which it should not have done. #{last_response.status}"
  end

  def test_forfillment_invalid_string_order_works
    post '/forfill/fredsentme'
    assert !last_response.ok?, "Platform errored which it should not have done. #{last_response.status}"
  end

  def test_forfillment_invalid_numeric_order_works
    post '/forfill/12345678987'
    assert !last_response.ok?, "Platform errored which it should not have done. #{last_response.status}"
  end
end
