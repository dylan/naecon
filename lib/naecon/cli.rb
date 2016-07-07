require 'readline'
require 'thor'

module Naecon
  class CLI < Thor

    no_commands {
      def start
        @store = Naecon::Store.new
      end
    }

    desc 'repl', 'Starts a REPL.'
    # Starts a REPL.
    def repl
      start

      list = %w(shards).sort

      comp = proc { |s| list.grep(/^#{Regexp.escape(s)}/) }

      Readline.completion_append_character = ' '
      Readline.completion_proc = comp

      stty_save = %x`stty -g`.chomp

      trap("INT") { system "stty", stty_save; exit }

      while line = Readline.readline('> ', true)
        case line
        when /^shards/
          @store.shards.each do |shard|
            puts shard.name
          end
        when /^exit/, /^\:q/, /^quit/
          exit
        end
      end
    end

  end

end
