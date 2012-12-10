module Icq
  module OSCAR
    module Generic
      def set_ex message
        data = pack_tlv(0x06, [0x0, 0x0].pack('nn'))

        value = [0x0002, 0x04, message.length + 4, message.length, message, 0x00].pack('nccna*n')
        data << pack_tlv(0x1d, value)

        send_snac 0x01, 0x1e, data
      end

      def set_away message
        data = pack_tlv(0x03, 'text/aolrtf; charset="us-ascii"')
        data << pack_tlv(0x04, message)
        send_snac 0x02, 0x04, data
      end
    end
  end
end
