module Icq
  module OSCAR
    module Admin
      def change_account_info options, &block
        data = ''
        data << pack_tlv(0x02, options[:new_password]) if options[:new_password]
        data << pack_tlv(0x12, options[:old_password]) if options[:old_password]

        rid = next_request_id
        send_snac 0x07, 0x05, data, request_id: rid
        client_handlers[rid] = block
        add method(:handle_change_account_info_ack), request_id: rid
      end

      def handle_change_account_info_ack
        debug ''
        while @snac.length > 0
          flags, count = @snac.unpack! 'vv'
          debug { { flags: '0x%02x' % flags } }
          count.times do
            type, tlv_data = slice_tlv data
            debug { { type: '0x%02x' % type, data: tlv_data.unpack('H*') } }
          end
        end
      end
    end
  end
end
