require 'data_mapper'
require './order'

class Customer
  include DataMapper::Resource

  property :id, Serial
  property :number, String
  has n, :orders

  #Finds or creates a customer record...
  def self.resolve number
    Customer.first(:number => number) || Customer.create(:number => number)
  end

  def current_order
    orders.first(:fulfilled => false)
  end

  def can_order
    orders.all(:fulfilled => false).count == 0
  end

end
