require 'pstore'
require 'json'
require 'net/http'
require 'pry'
require 'naecon/models/item'
require 'naecon/models/nation'
require 'naecon/models/shop'
require 'naecon/models/port'
require 'naecon/models/shard'

module Naecon
  # Acts as the store for Naecon, manages saving and storing old data from
  # the api.
  class Store
    attr_reader :items, :shards, :ports, :nations

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
      @shards         = {}
      @ports          = {}
      @nations        = {}


      @pstore = PStore.new('data.pstore')

      transaction { @last_modified = @pstore[:last_modified] }

      expiration = @last_modified + (60 * 60 * 24) unless @last_modified.nil?
      # Has it been a day since we last fetched?
      if @last_modified.nil? || expiration < Time.now
        puts 'Downloading...'
        fetch
      else
        transaction do
          @shards  = @pstore[:Shards]
          @items   = @shards[0].items
          @ports   = @shards[0].ports
          @nations = @shards[0].nations
        end
      end
    end

    def transaction(&_block)
      @pstore.transaction { yield }
    end

    # Fetches the data from the NA API
    def fetch
      @shard_prefixes.each do |prefix|
        data = {}
        shard_name = prefix
        prefix = "#{@shard_prefix}#{prefix}"
        @filenames.map do |filename|
          filename = filename.sub(/\*/, prefix)
          puts "Fetching #{filename}..."

          index = @filters.select { |_, value| filename.match value }
          key = index.values[0]
          data[key] = download(@host, "#{@path_prefix}#{filename}")
        end
        save Shard.new(shard_name, data)
      end
      binding.pry
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

    def save(value)
      transaction do
        @pstore[:Shards] ||= []
        @pstore[:Shards].push(value)
        @pstore[:last_modified] = Time.now
      end
    end
  end
end
