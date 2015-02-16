# An SMS Powered Coffee Shop

This is a simple Ruby and Sinatra app to allow you to run your ordering system (build with a coffeeshop in mind) from a Twilio SMS number.

## Features

- SMS Receiver
- Database Backed
- Pusher for Realtime Updates
- Designed to have multiple Ordering Pads (iPads probably...)

## Turn Key

The SMSCoffeeShop is pretty much ready to go out of the box. You need to set the following Environment Variables to make it work:

* `DATABASE_URL` This is the URL used for database. If you deploy to Heroku it will be automagically set.
* `PUSHER_URL` This is the URL used for your Pusher app, so that the system can push the updates to the tablet device.
* `PUSHER_KEY` This is the Pusher Application Key so that the tablet app can subscribe to notifications of orders etc.
* `TWILIO_ACCOUNT_SID` and `TWILIO_AUTH_TOKEN` These are your Twilio credentials so that SMSCoffeeShop can use your Twilio account to send SMS messages.
* `TWILIO_NUMBER` This is the advertised number. It is the number your customer will send SMS messages *to* when ordering a coffee. SMSCoffeeShop needs to know this number so that it can send out completion notifications. Don't foreget to configure this number in your Twilio Dahsboard to `http://<your server/app name>/order`.
* `ENABLE_SMS` This should be set to `YES` if you want the system to actually send out SMS messages. This is useful for load and performance testing the application. On a typical Heroku instance it can handle over 1000 coffees a minute, so that should be fine. (Although not if SMS is enabled, as Twilio slightly increases response times as API calls are made on the main thread.)
* `SUPERVISOR_NUMBER` This is telephone number of the Twilio person at the event. If anything goes wrong, error messages will be sent to this number providing instructions on what you should do.

Finally, you need to configure the drinks you are serving at the coffee stand. This is a simple matter of editing the Hash in `order.rb`. The official name is how the system will reply to the user, and to the Barista. However it will match based on the values in `corruptions`, which should include all acceptable spellings (including the correct one).

Deploy the app, and you're ready to go. Point a tablet at `http://<your server/app name>/coffee-shop-bar-manager-thingy-do-dar`, and the Baristas will see the ordering process.

## Development

To use in development, copy `.env.example` to `.env` and fill in your development credentials.

Run the application with

```shell
$ bundle exec foreman start
```

The application will start on http://localhost:5000/.

## Test

To run the tests, make sure you have your credentials set in a `.env` file. If you want to use different credentials to development (i.e. a different DATABASE_URL) then you can create a `.env.test` file to override the `.env` file.

Run the tests with

```shell
$ ruby shop_test.rb
```
