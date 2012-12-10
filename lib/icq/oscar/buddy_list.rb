module Icq
  module OSCAR
    module BuddyList
      def handle_03_0b
        hash = {}
        hash[:username] = slice_string @snac

        # @listener.handle_presence_online hash
      end
    end
  end
end
