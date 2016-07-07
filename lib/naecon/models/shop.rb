class Shop
  attr_reader :port
  def initialize(info)
    @port = info['Id'].to_i # NAME
    @items = info['RegularItems'].map do |e|
      {
        e['TemplateId'].to_i => {
          quantity: e['Quantity'],
          sell_price: e['SellPrice'],
          buy_price: e['BuyPrice']
        }
      }
    end
  end
end
