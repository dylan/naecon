require 'readline'

module Naecon
  class CLI < Thor
    def initialize
      @store = Naecon::Store.new
    end

    desc 'Starts a REPL.'
    def repl
      LIST = %w( search
                 download
                 open
                 help
                 history
                 quit
                 url
                 next
                 clear
                 prev
                 past ).sort

      comp = proc { |s| LIST.grep(/^#{Regexp.escape(s)}/) }

      Readline.completion_append_character = ' '
      Readline.completion_proc = comp

      stty_save = %x`stty -g`.chomp

      trap("INT") { system "stty", stty_save; exit }

      while line = Readline.readline('> ', true)
        case line
        when 'shards'
          store.shards.each do |shard|
            puts shard.name
          end
        when 'exit' || ':q' || 'quit'
          exit
        end
      end
    end


  end

end
