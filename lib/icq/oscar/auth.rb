module Icq
  module OSCAR
    module Auth
      Roasting_Data = [ 0xF3, 0x26, 0x81, 0xC4,
        0x39, 0x86, 0xDB, 0x92,
        0x71, 0xA3, 0xB9, 0xE6,
        0x53, 0x7A, 0x95, 0x7C ]

      def roast password
        passnum = password.unpack('C*')
        roasted = []
        passnum.each_index { |index|
          roasted << (passnum[index] ^ Roasting_Data[index % Roasting_Data.length])
        }
        roasted.pack('c*')
      end

      def handle_authorizer_signon
        debug ''
        send_flap 0x01, [
          [1].pack('N'),
          pack_tlv(0x1, @username),
          pack_tlv(0x2, roast(@password)),
          pack_tlv(0x3, 'Ruby OSCAR Library'),
          pack_tlv_word(0x16, 0xbeef),
          pack_tlv_word(0x17, 0x1),
          pack_tlv_word(0x18, 0x0),
          pack_tlv_word(0x19, 0x0),
          pack_tlv_word(0x1a, 0x0),
          pack_tlv_int(0x14, 0x1),
          pack_tlv(0x0f, 'en'),
          pack_tlv(0x0e, 'us')
        ].join

        add method(:handle_authorization_response), channel: 4
      end

      def handle_authorization_response
        while @flap.length > 0
          type, value = slice_tlv @flap
          case type
          when 0x01
            #sn = value
          when 0x05
            @addr_port = value
          when 0x06
            @cookie = value
          when 0x08
            error_code = value.unpack('n').first
          else
          end
        end

        if error_code || @addr_port.nil?
          debug { :error_code }
          @listener.auth_error error_code
          add -> {}, unbind: true
        else
          add method(:connect_bos), unbind: true
        end

        close_connection
      end

      def connect_bos
        server, port = *@addr_port.split(':')
        port = port.to_i
        reconnect server, port
        @addr_port = nil

        @state = :bos_connecting
      end

      Family_Versions = { 0x01 => 3, 0x02 => 1, 0x03 => 1, 0x04 => 1,
        0x06 => 1, 0x09 => 1, 0x0a => 1, 0x0b => 1, 0x13 => 1, 0x15 => 1 }

      def handle_bos_signon
        send_flap 0x01,
          [1, pack_tlv(0x06, @cookie)].pack('Na*')

        add method(:handle_01_03), snac: [0x01, 0x03]
      end

      def handle_01_03
        services = @snac.unpack 'n*'
        debug { { services: services.map { |v| '0x%02x' % v }.join(', ') } }

        data = Family_Versions.map { |f, v| [f, v].pack('nn') }.join
        send_snac 0x01, 0x17, data
        add method(:handle_01_18), snac: [0x01, 0x18]
      end

      def handle_01_18
        services = Hash[*@snac.unpack('n*')]
        debug { { services: services.map do |k,v| '0x%02x -> 0x%02x' % [k,v] end.join(', ') } }

        request_roster
      end

      def handle_roster_last
        send_snac 0x13, 0x07

        data =
          Family_Versions.map do |family, version|
          [family, version, 0x0110, 0x047B].pack('nnnn')
          end.join
          send_snac 0x01, 0x02, data

          add method(:handle_03_0b), snac: [0x03, 0x0b]
          add method(:handle_04_07), snac: [0x04, 0x07]
          add method(:handle_04_0a), snac: [0x04, 0x0a]
          add method(:handle_13_1c), snac: [0x13, 0x1c]
          add method(:handle_bos_ch4), channel: 4

          @listener.ready
      end

      def handle_bos_ch4
        while @flap.length > 0
          type, value = slice_tlv @flap
          case type
          when 0x09
            disconnect_reason = value.unpack('n').first
          end
        end

        if disconnect_reason == 1
          add -> {}, unbind: true
          @listener.handle_abuse
        end

        # TODO update
        @connection = nil
      end
    end
  end
end
