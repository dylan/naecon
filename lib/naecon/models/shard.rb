# Represents a Naval Action Shard/Server.
class Shard
  attr_reader :name,
              :items,
              :ports,
              :nations

  def initialize(name, raw_data)
    @filters = { Items:    'ItemTemplates',
                 Nations:  'Nations',
                 Shops:    'Shops',
                 Ports:    'Ports' }

    @name    = name.to_sym
    @items   = {}
    @nations = {}
    @shops   = {}
    @ports   = {}

    process(raw_data)
  end

  def process(raw_data)
    raw_data.each do |key, value|
      case key
      when @filters[:Items]
        @items = make_new(Item, value)
      when @filters[:Nations]
        @nations = make_new(Nation, value['Nations'])
      when @filters[:Shops]
        @shops = make_new(Shop, value)
      when @filters[:Ports]
        @ports = make_new(Port, value)
      end
    end
  end

  def make_new(type, values)
    collection = {}
    i = 0
    values.each do |value|
      begin
        collection[value['Id'].to_i] = type.new(value)
        i += 1
      rescue StandardError => e
        # puts e.backtrace.join("\n")
        # puts e.message
        # puts "Skipped"
        # puts "--------"
        # puts value.inspect
      end
    end
    puts "#{collection.count} #{type.pluralize}"
    collection
  end

  def view_shops
    result = {}
    @shops.each do |_, shop|
      port_name = @ports[shop.port].name
      result[shop.port] = portName
    end
    result
  end

  def port(id)
    @ports.select(id)
  end

end
