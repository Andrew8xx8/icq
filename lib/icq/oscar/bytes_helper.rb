module Icq
  module OSCAR
    module BytesHelper
      def pack_tlv type, value = ''
        [type, value.length, value].pack 'nna*'
      end

      def pack_tlv_word type, value
        [type, 2, value].pack 'nnn'
      end

      def pack_tlv_int type, value
        [type, 4, value].pack 'nnN'
      end

      def slice_tlv data
        type, length = data.unpack! 'nn'
        value = data.slice! 0...length
        return type, value
      end

      def slice_tlvs data
        hash = {}
        while data.length > 0
          type, value = slice_tlv data
          hash[type] = value
        end

        hash
      end

      def slice_string data
        data.slice! 0...data.slice!(0).getbyte(0)
      end
    end
  end
end
