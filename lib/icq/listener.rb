module Icq
  class Listener
    attr_accessor :client

    def authed
      puts 'authed'
    end

    def auth_error code
      puts %s(auth-error) => '0x%02x' % code
    end

    def connection_error
      puts 'connection-error'
    end

    def ready
      puts 'ready'

      @client.away_message_title = 'away message'
      @client.away_message_desc = 'away message desc'

      @client.set_xstatus OSCAR::XStatuses_Names.index('thinking')

      @client.send_message '412242415', '1'
    end

    def roster items
      puts items: items
    end

    def message username, text
      puts event: :message, username: username, text: text

      #@client.send_message username, 'echo: ' << text
    end
  end
end

