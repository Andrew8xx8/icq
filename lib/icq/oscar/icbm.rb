module Icq
  module OSCAR
    module ICBM
      def next_message_cookie
        rand 10000000
      end

      Message_Channel_Plaintext = 0x01
      Type_Message_Data = 0x0002
      Type_Server_Ack_Request = 0x0003
      Type_Store_If_Offline = 0x0006

      Family_Messages = 0x0004
      Messages_Subtype_Send = 0x0006

      def send_message username, message, options = {}
        debug { %w[username message options] }

        data = [0, next_message_cookie, Message_Channel_Plaintext, username.length, username].pack('NNnca*') <<
        pack_tlv(0x0002, pack_tlv_word(0x0501, 0x0001) << 
                 pack_tlv(0x0101, [Type_Message_Data, 0x0000, message.encode('utf-16be')].pack('nna*')))
                 data << pack_tlv(Type_Server_Ack_Request) if options[:ack]
                 data << pack_tlv(Type_Store_If_Offline) if options[:store]

                 send_snac Family_Messages, Messages_Subtype_Send, data

                 # @client_handlers[request_id] = options[:ack_block] if options[:ack_block]
                 # add_handler_on_request_id request_id, &method(:handle_message_ack) if options[:ack]
      end

      def slice_uin_online_user_info data
        uin = slice_string data
        warning_level, tlvs_count = data.unpack! 'nn'

        tlvs_count.times do
          slice_tlv data
        end

        uin
      end

      def handle_04_07
        cookie1, cookie2, channel = @snac.unpack! 'NNn'

        uin = slice_uin_online_user_info @snac

        debug { { channel: '0x%04x' % channel } }
        if channel == 0x01
          type, value = slice_tlv @snac
          data = value
          while data.length != 0
            type, value = slice_tlv data
            debug { { type: '0x%04x' % type, value: value } }
            case type
            when 0x0101
              encoding, language, text = value.unpack 'nna*'
              debug { { encoding: '0x%02x' % encoding } }
            when 0x0501
            end
          end

          text.force_encoding(encoding == 2 ? 'utf-16be' : 'windows-1251').encode!('utf-8')

          @listener.message uin, text
        elsif channel == 0x02
          type, value = slice_tlv @snac
          data = value

          debug { { data: @snac.unpack('H*') } }
          h = {}

          @snac.unpack! 'nNN'
          h[:cap] = @snac.slice! 0...16

          if h[:cap] == ICQ_Relay_Cap
            h[:relay] = true
            while @snac.length != 0
              type, value = slice_tlv @snac
              case type
              when 0x2711
                e_data = value
              end
            end

            data = e_data

            h[:len1], h[:proto_ver] = data.unpack!('vv')
            h[:plugin] = data.slice! 0...16

            data.unpack! 'vVcv'
            data.unpack! 'vv'
            data.slice! 0...12

            if h[:plugin] == "\x00" * 16
              h[:message_type] = data.unpack!('C').first
              data.unpack!('Cvv')

              h[:message] = data.slice!(0...data.unpack!('v').first).unpack('Z*').first
              if h[:message_type] == 0x1a
                send_xstatus uin, cookie1, cookie2
                debug 'send_xs'
              end
            end
          end

          debug { %w[uin h] }
        end
      end

      def handle_04_0a
        while @snac.length != 0
          channel = @snac.unpack! 'n'
          debug { :channel }

          uin = slice_uin_online_user_info @snac
          count, reason = @snac.unpack! 'nn'

          debug { { count: count, reason: '0x%04x' % reason } }
        end
      end

      def safe_xml xml
        xml.gsub('<', '&lt;').gsub('>', '&gt;')
      end


      def plugin_type_id
        data = ''
        data << [0x4f].pack('v')
        data << [0x3b60b3ef, 0xd82a6c45, 0xa4e09c5a, 0x5e67e865].pack('NNNN')
        data << [0x0008].pack('v')
        data << [0x002a].pack('V')
        data << 'Script Plug-in: Remote Notification Arrive'
        data << [0x00000100, 0x00000000, 0x00000000, 0x0000, 0x00].pack('NNNnc')
        data
      end

      attr_accessor :xstatus, :away_message_title, :away_message_desc

      def send_xstatus username, cookie1, cookie2
        xstatus = 23
        title = 'Title'
        desc = 'Desc'
        status = 0x0

        content = "<ret event='OnRemoteNotification'>" <<
        "<srv><id>cAwaySrv</id>" <<
        "<val srv_id='cAwaySrv'><Root>" <<
        "<CASXtraSetAwayMessage></CASXtraSetAwayMessage>" <<
        "<uin>#{username}</uin>" <<
        "<index>#{@xstatus || 0}</index>" <<
        "<title>#{@away_message_title || ''}</title>" <<
        "<desc>#{@away_message_desc || ''}</desc></Root></val></srv></ret>"

        query = "<NR><RES>#{safe_xml content}</RES></NR>"

        data = ''
        data << [0x1b].pack('v')
        data << [0x08].pack('c')
        data << "\x00" * 16
        data << [0x03].pack('N')
        data << [0x0004].pack('N')
        msgc = [rand(127), rand(127)].pack('cc')
        data << msgc
        data << [0x0e].pack('v')
        data << msgc
        data << [0, 0, 0].pack('NNN')
        data << [0x1a, 0x0].pack('cc')
        data << [status].pack('v')
        data << [0x0100].pack('n')
        data << [0x0100, 0x00].pack('nc')
        data << plugin_type_id

        data << [query.length + 4, query.length].pack('VV')
        query.force_encoding('ascii-8bit')
        data << query

        data = [cookie1, cookie2, 0x02, username.length,
          username, 0x03, data].pack('NNnca*na*')

        send_snac 0x04, 0x0b, data
      end
    end
  end
end
