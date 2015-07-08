require 'bundler'
Bundler.require
require 'json'
require './order'

include Twilio::REST
include Twilio::TwiML

DataMapper.setup(:default, ENV['DATABASE_URL'])

def push_to_squeezer order
  Pusher.url = ENV['PUSHER_URL']
  Pusher['orders'].trigger('order', {
    id: order.id,
    product: order.standard_name,
    message: order.raw
  })
end

def remove_order_from_squeezer order
  Pusher.url = ENV['PUSHER_URL']
  Pusher['orders'].trigger('remove', {
    id: order.id
  })
end

def client
  Client.new ENV['TWILIO_ACCOUNT_SID'], ENV['TWILIO_AUTH_TOKEN']
end

# We can use this to setup the database,
configure do
  #Finalize and store our models.
  DataMapper.finalize.auto_upgrade!
end

get '/wakeup' do
  "OK"
end

#Simple Page to show all the steps.
get '/coffee-shop-bar-manager-thingy-do-dar' do
  @orders = Order.all(:fulfilled => false, :order => [ :time  ])
  erb :index, :layout => :main_layout
end

# When an order is complete, we use AJAX to call this route.
post '/forfill/:id' do
  order = Order.get(params[:id].to_i)
  if order
    order.fulfilled = true
    order.status = "COMPLETED FOR COLLECTION"
    if order.save
      client.account.messages.create(to: order.customer.number,
        from: ENV['TWILIO_NUMBER'],
        body: "Your #{order.standard_name} is ready. You can collect it from the coffee shop right away, ask for order number #{order.id}."
      ) if ENV['ENABLE_SMS'] == "YES"
      remove_order_from_squeezer order
      {"status" => "ok"}.to_json
    else
      {"status" => "nok"}.to_json
    end
  else
    status 404
    {"status" => "nok"}.to_json
  end
end

post '/cancel/:id' do
  order = Order.get(params[:id].to_i)
  if order
    order.fulfilled = true
    order.status = "CANCELLED BY SQUEEZER"
    if order.save
      client.account.messages.create(to: order.customer.number,
        from: ENV['TWILIO_NUMBER'],
        body: "We're really sorry, but the Barista cancelled your order. We're going to go and talk to them to make sure everything is okay."
      ) if ENV['ENABLE_SMS'] == "YES"
      remove_order_from_squeezer order
      {"status" => "ok"}.to_json
    else
      {"status" => "nok"}.to_json
    end
  else
    status 404
    {"status" => "nok"}.to_json
  end
end

get '/stats' do
  customers = Customer.count || 0
  orders = Order.count || 0
  fulfilled_orders = Order.all(:fulfilled => true).count || 0
  unfulfilled_orders = Order.all(:fulfilled => false).count || 0
  canceled = Order.all(:status => "CANCELLED BY SQUEEZER").count || 0
  delivered = Order.all(:status => "COMPLETED FOR COLLECTION").count || 0
  @status = {
    :customers => customers,
    :total_orders => orders,
    :fulfilled => fulfilled_orders,
    :unfulfilled => unfulfilled_orders,
    :delivered => delivered,
    :cancelled => canceled
  }
  erb :status, :layout => :main_layout
end

# An SMS has been sent. We need to convert this to an order...
post '/order' do
  content_type 'text/xml'

  customer = Customer.resolve params[:From]
  message = "Oops. Something went terribly wrong. Sad Panda. This has been reported."
  order = nil

  # This cannot fuck up. If it does, we need to know.
  begin
    if params[:Body].downcase == "help"
      message = "Oh dear. We're going to give you a call in just a few minutes to help you."
      client.account.messages.create(to: ENV['SUPERVISOR_NUMBER'], from: ENV['TWILIO_NUMBER'], body: "Someone is having a problem: #{params[:From]}") if ENV['ENABLE_SMS'] == "YES"
    elsif customer.can_order == false
      message = "We're still making you a #{customer.current_order.standard_name}, if something is wrong, reply with 'HELP' and we will try and fix things..."
    else
      order = Order.create(:raw => params[:Body].downcase, :customer => customer )
      order.status = "CREATED"
      if order.valid_order
        order.status = "PUSHED TO SQUEEZER"
        push_to_squeezer order
        message = "Thanks for ordering a #{order.standard_name} from the SMS Coffee Shop powered by Twilio. We'll text you back when it's ready. In the mean time, why not find out more about adding SMS and Voice calling to your applications with Twilio at https://www.twilio.com"
      else
        order.status = "REJECTED NONSENSE"
        message = "Twilio's SMS Coffee Shop doesn't know how to make #{params[:Body]}... We can make #{Order.options_list}."
      end
      order.save
    end

  rescue Exception => e
    puts "Something bad happened: #{e.message}"
    client.account.messages.create(to: ENV['SUPERVISOR_NUMBER'], from: ENV['TWILIO_NUMBER'], body: "SMS CoffeeShop Error: #{e.message}") if ENV['ENABLE_SMS'] == "YES"
  end

  response.headers['x-order-id'] = order.id.to_s if order != nil
  Response.new { |response| response.Message message }.text
end

