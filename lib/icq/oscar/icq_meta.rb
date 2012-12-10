module Icq
  module OSCAR
    module IcqMeta
      def pack_tlv_le type, value
        [type, value.length, value].pack 'vva*'
      end

      def pack_tlv_asciiz_le type, string
        string = string.force_encoding('utf-8').encode('windows-1251')
        pack_tlv_le type, [string.length, string].pack('vZ*')
      end

      def update_user_info hash, &block
        tlvs = ''
        tlvs << pack_tlv_asciiz_le(0x0154, hash[:nickname]) if hash[:nickname]
        tlvs << pack_tlv_asciiz_le(0x0140, hash[:firstname]) if hash[:firstname]
        tlvs << pack_tlv_asciiz_le(0x014a, hash[:lastname]) if hash[:lastname]
        tlvs << pack_tlv_le(0x02f8, [1].pack('c')) if hash[:authorization]
        tlvs << pack_tlv_asciiz_le(0x0258, hash[:about]) if hash[:about]

        data = [@username.to_i, 0x07d0, 0x0002, 0x0c3a].pack('Vvvv') << tlvs
        meta_data_tlv = pack_tlv 0x0001, [data.length].pack('v') << data

        request_id = next_request_id
        send_snac 0x0015, 0x0002, meta_data_tlv, flags: 0x0001, request_id: request_id
        @client_handlers[request_id] = block
        add method(:handle_update_user_info), request_id: request_id
      end

      def handle_update_user_info
        debug { :@snac }
        type, data, empty_data = slice_tlv @snac
        debug { :@snac }

        data_chunk_size, uin, data_type, request_sequence_number,
          data_subtype = @snac.unpack! 'vVvvv'

        debug { { data_chunk_size: data_chunk_size, uin: uin, data_type: data_type,
          request_sequence_number: '0x%04x' % request_sequence_number,
          data_subtype: '0x%04x' % data_subtype } }

        success_byte = @snac.unpack!('c').first
        debug { { success_byte: '0x%02x' % success_byte } }

        @client_handlers.delete(request_id).call(success_byte == 0x0a)
      end

      def update_password pass, &block
        debug { :pass }

        data = [@username.to_i, 0x07d0, 0x0002, 0x042e].pack('Vvvv') << [pass.length, pass].pack('vZ*')
        puts "d = #{data.unpack 'H*'}"
        meta_data_tlv = pack_tlv 0x0001, [data.length].pack('v') << data

        request_id = next_request_id
        send_snac 0x0015, 0x0002, meta_data_tlv, flags: 0x0001, request_id: @request_id
        @client_handlers[@request_id] = block
        add method(:handle_update_password), request_id: @request_id
      end

      def handle_update_password
        type, data = slice_tlv @snac

        data_chunk_size, uin, data_type, request_sequence_number, 
          data_subtype = @snac.unpack! 'vVvvv'

        debug { { data_chunk_size: data_chunk_size, uin: uin, data_type: data_type,
          request_sequence_number: '0x%04x' % request_sequence_number,
          data_subtype: '0x%04x' % data_subtype } }

        success_byte = @snac.unpack!('c').first

        client_handlers.delete(@request_id).call(success_byte == 0x0a)
      end
    end
  end
end
