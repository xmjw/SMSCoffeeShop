#Just in case we reuse this elsewhere.
require 'data_mapper'
require './customer'

#A model to hold the call tree.
class Order
  include DataMapper::Resource

  property :id, Serial
  property :time, DateTime
  property :fulfilled, Boolean
  property :raw, String
  property :standard_name, String
  property :status, String

  belongs_to :customer, :required => true

  def self.by_id id
    Order.get(id)
  end

  def self.options
    [
      {
        :corruptions => %w(expreso expresso espresso shot\ of\ coffee short),
        :standard_name => "Espresso",
        :options => {}
      },
      {
        :corruptions => %w(expreso\ macchiato expresso\ macchiato espresso\ macchiato machiato macchaito macheato macchiatoe),
        :standard_name => "Espresso Macchiato",
        :options => {}
      },
      {
        :corruptions => %w(cappacino capacino cappacino cappocino capocino capacino cappucino cappuccino),
        :standard_name => "Cappuccino",
        :options => {}
      },
      {
        :corruptions => %w(late lattey larte lartte lartay lattee latte cafe\ late caffee\ latte cafee\ late cafee\ late cafe\ latte caffe\ latte caffè\ latte),
        :standard_name => "Caffè Latte",
        :options => {}
      },
      {
        :corruptions => %w(white\ coffee flat\ white americano black\ coffee coffee long\ black caffè caffe),
        :standard_name => "Caffè",
        :options => {}
      },
      {
        :corruptions => %w(hot\ chocolate chocolate cocco coco choco-schock choco\ schock choco),
        :standard_name => "Choco-Schock",
        :options => {}
      },
      {
        :corruptions => %w(tea white\ tea black\ tea chai tee tae cup\ of\ tea cuppa brew tee english\ breakfast peppermint green\ tea green),
        :standard_name => "Tea",
        :options => {}
      },
      {
        :corruptions => %w(caffe\ getreide caffe\ latte\ getreide caffè\ latte\ getreide getreide caffe\ getreide),
        :standard_name => "Caffè Latte Getreide",
        :options => {}
      }
    ]
  end

  def self.options_list
    #Creates a nice list of the possible options so we can change the above hash at will, or get it from another file.
    drinks = options.collect {|opt| opt[:standard_name]}
    drinks[0...-1].inject(""){|str,item| str = "#{str}#{item}, "} + "and #{drinks.last}"
  end

  def valid_order
    if extract_order
      true
    else
      self.fulfilled = true
      self.time = DateTime.now
      save
      false
    end
  end

  private

  def extract_order
    is_valid = false
    puts self.raw
    Order.options.each do |drink|
      drink[:corruptions].each do |spelling|
        if self.raw.include? spelling
          is_valid = true
          self.standard_name = drink[:standard_name]
          self.fulfilled = false
          self.time = DateTime.now
        end
      end
    end

    is_valid
  end
end







