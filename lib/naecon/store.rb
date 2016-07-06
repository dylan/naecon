require 'pstore'
require 'json'
require 'net/http'
require 'pry'
require 'models/item'

module Naecon
  # Acts as the store for Naecon, manages saving and storing old data from
  # the api.
  class Store
    attr_reader :items

    def initialize
      @host           = 'storage.googleapis.com'

      @path_prefix    = '/nacleanopenworldprodshards/'
      @shard_prefix   = 'cleanopenworldprod'
      @shard_prefixes = %w( eu1
                            us1
                            us2 )

      @filenames      = %w( ItemTemplates_*.json
                            Shops_*.json
                            Nations_*.json
                            Ports_*.json )
      @filters        = { Items:    'ItemTemplates',
                          Nations:  'Nations',
                          Shops:    'Shops',
                          Ports:    'Ports' }
      @items          = {}

      @pstore = PStore.new('data.pstore')

      @pstore.transaction do
        @last_modified = @pstore[:last_modified]
      end

      expiration = @last_modified + (60 * 60 * 24) unless @last_modified.nil?
      # Has it been a day since we last fetched?
      if @last_modified.nil? || expiration < Time.now
        puts 'Downloading...'
        fetch
      else
        @pstore.transaction do
          binding.pry
          json = @pstore[:cleanopenworldprodeu1]["ItemTemplates_cleano"]
          json.each do |item|
            @items[item[:Id]] = item
          end
        end
      end
    end

    # Fetches the data from the NA API
    def fetch
      @shard_prefixes.each do |prefix|
        data = {}
        country = prefix
        prefix = "#{@shard_prefix}#{prefix}"
        @filenames.map do |filename|
          filename = filename.sub(/\*/, prefix)
          puts "Fetching #{filename}..."

          index = @filters.select { |_, value| filename.match value }
          key = index.values[0]
          data[key] = download(@host, "#{@path_prefix}#{filename}")
        end
        transform(country, data)
        # save(country, data)
      end
    end

    def download(host, filename)
      clean(Net::HTTP.get(host, filename))
    end

    def clean(response)
      filters = { Ports:    /^.*var Ports \=/,
                  Nations:  /^.*var Nations \=/,
                  Items:    /^.*var ItemTemplates \=/,
                  Shops:    /^.*var Shops \=/ }

      filters.select { |_, value| response.match value }.keys.each do |key, _|
        response.gsub!(filters[key], '')
      end
      response.delete!(';')
      JSON.load response
    end

    def transform(country, data)
      data.each do |key, value|
        case key
        when @filters[:Items]
          items = {}
          value.each do |value|
            items[value['Id'].to_sym] = Item.new(value)
          end
          binding.pry
        when @filters[:Nations]
          puts 'Nations'
        when @filters[:Shops]
          puts 'Shops'
        when @filters[:Ports]
          puts 'Ports'
        end
      end
    end

    def save(key, value)
      @pstore.transaction do
        @pstore[key.to_sym] = value
        @pstore[:last_modified] = Time.now
      end
    end
  end
end
