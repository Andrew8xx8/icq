module Icq
  module OSCAR
    module Connection
      def post_init
        @state = :auth_connecting
      end

      def connection_completed
        debug ''

        @data = ''

        @channel_handlers = {}
        @request_id_handlers = {}
        @snac_handlers = {}
        @client_handlers = {}

        @keepalive_timer = EM.add_periodic_timer 60 do
          send_flap 0x05
        end

        case @state
        when :auth_connecting
          add method(:handle_authorizer_signon), channel: 0x01
          @state = :auth_connected
        when :bos_connecting
          add method(:handle_bos_signon), channel: 0x01
          @state = :bos_connected
        end
      end

      def receive_data data
        @data << data

        loop do
          unless @flap_length
            return if @data.length < 6
            header = @data.slice! 0...6
            asterisk, @channel, sequence, @flap_length = header.unpack 'aCnn'
          else
            return if @data.length < @flap_length
            @flap = @data.slice!(0...@flap_length)
            @flap_length = nil
            handle_flap
          end
        end
      end

      def unbind
        debug ''

        EM.cancel_timer @keepalive_timer

        if @unbind_handler
          debug '@unbind_handler.call'
          @unbind_handler.call
          @unbind_handler = nil
        else
          debug '@listener.connection_error'
          @listener.handle_connection_error
        end
      end

      def add handler, options = {}
        debug { %w[handler options] }
        case
        when ch = options[:channel]
          @channel_handlers[ch] = handler
        when id = options[:request_id]
          @request_id_handlers[id] = handler
        when snac = options[:snac]
          @snac_handlers[snac] = handler
        when options[:unbind]
          debug 'unbind = true'
          @unbind_handler = handler
        end
      end

      def handle_flap
        debug { :@channel }
        if @channel_handlers.has_key? @channel
          @channel_handlers.delete(@channel).call
          return
        end

        if @channel == 0x02
          @family, @subtype, @flags, @request_id = @flap.unpack! 'nnnN'
          @snac = @flap
          @flap = nil
          debug { { family: '0x%02x' % @family, subtype: '0x%02x' % @subtype } }

          if @flags == 1 << 15
            trash_length = @snac.unpack!('n').first
            @snac.slice! 0...trash_length
          end

          if @request_id_handlers.has_key? @request_id
            @request_id_handlers.delete(@request_id).call
            return
          end

          if @snac_handlers.has_key? key = [@family, @subtype]
            @snac_handlers[key].call
            return
          end
        end
      end

      def next_sequence
        @sequence = rand(65535) unless @sequence
        @sequence += 1
        @sequence = 0 if @sequence == 65535
        @sequence
      end

      def send_flap type, data = ''
        # debug { "data = #{data.unpack('H*').join}" }
        send_data ['*', type, next_sequence, data.length, data].pack('aCnna*')
      end

      def next_request_id
        @request_id = rand 2147483647 unless @next_request_id
        @request_id += 1
        @request_id = 0 if @request_id == 2147483647
        @request_id
      end

      def send_snac family, subtype, data = nil, options = {}
        request_id = options[:request_id] || next_request_id
        flags = options[:flags] || 0

        if block = options[:on_response]
          @request_id_handlers[request_id] = block
        end
        # debug { "request_id = #{request_id}, data = #{data.unpack('H*').join}" }
        snac = [family, subtype, flags, request_id, data].pack 'nnnNa*'
        send_flap 0x02, snac
      end
    end
  end
end
