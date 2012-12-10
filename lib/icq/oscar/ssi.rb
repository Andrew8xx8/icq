module Icq
  module OSCAR
    module SSI
      def send_13_04
        send_snac 0x13, 0x04, '', on_response: method(:handle_13_06)
      end

      def send_13_07
        send_snac 0x13, 0x07, ''
      end

      alias :request_roster :send_13_04

      def handle_13_1c
        uin = slice_string @data
        debug { :uin }

        @listener.added uin
      end

      def handle_13_06
        roster = (@multiresponse_data[@request_id] ||= [])

        @snac.unpack! 'C'
        count = @snac.unpack!('n').first
        items = []
        groups = {}
        count.times do
          item_name = @snac.slice! 0...@snac.unpack!('n').first
          item_group_id, item_id, item_type = @snac.unpack!('nnn')

          tlvs = slice_tlvs(@snac.slice!(0...@snac.unpack!('n').first))
          item_nickname = tlvs[0x0131]
          item_nickname.force_encoding('utf-8') if item_nickname

          debug { %w[item_name item_group_id item_id item_type tlvs] }
          if item_type == 0x00
            items << { name: item_nickname, uin: item_name, group_id: item_group_id }
          elsif item_type == 0x01
            groups[item_group_id] = item_name
          end

          item_id
        end

        debug { :groups }
        items.each do |item|
          gid = item.delete :group_id
          item[:group] = groups[gid]
          roster << item
        end

        if @flags & 1 == 0
          @snac.unpack!('n')
          @listener.roster @multiresponse_data.delete(@request_id)
          handle_roster_last
        else
          add method(:handle_13_06), request_id: @request_id
        end
      end
    end
  end
end
