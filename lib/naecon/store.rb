require 'pstore'
require 'json'
require 'net/http'

module Naecon
  # Acts as the store for Naecon, manages saving and storing old data from
  # the api.
  class Store
    # Fetches the data fromt he NA API
    def fetch
      @host           = 'storage.googleapis.com'

      @path_prefix    = '/nacleanopenworldprodshards/'

      @shard_prefixes = %w( cleanopenworldprodeu1
                            cleanopenworldprodus1
                            cleanopenworldprodus2 )

      @filenames      = %w( ItemTemplates_*.json
                            Shops_*.json
                            Nations_*.json
                            Ports_*.json )

      @filenames.map do |filename|
        @shard_prefixes.each do |prefix|
          filename = filename.sub(/\*/, prefix)
          save(prefix, download(@host, "#{@path_prefix}#{filename}"))
        end
      end
    end

    def download(host, filename)
      clean(Net::HTTP.get(host, filename))
    end

    def clean(response)
      response.read
              .gsub!(/^.*var Ports \=/, '')
              .gsub!(/^.*var Nations \=/, '')
              .gsub!(/^.*var Items \=/, '')
              .gsub!(/^.*var Shops \=/, '')
              .gsub!(/^.*\;/, '')
      response
    end

    def save(key, value)
      @pstore = PStore.new('data.pstore')
      @pstore.transaction do
        @pstore[key.to_sym] = value
        @pstore[:last_modified] = Time.now
      end
    end
  end
end
