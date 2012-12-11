module Icq
  class Client

    # @private
    attr_accessor *Configuration::VALID_OPTIONS_KEYS
    attr_accessor :options
    attr_reader :control_uri, :control, :connection

    # Creates a new API
    def initialize(options={})
      self.options = options
      merged_options = Icq.options.merge(options)
      Configuration::VALID_OPTIONS_KEYS.each do |key|
        send("#{key}=", merged_options[key])
      end
      @callbacks = {}

      on('ready') {}
      on('roster') {}
      on('auth_error') {}
      on('connection_error') {}
    end

    def on_authed(&block)
      on('authed', &block)
    end

    def on_auth_error(&block)
      on('auth_error', &block)
    end

    def on_connection_error(&block)
      on('connection_error', &block)
    end

    def on_ready(&block)
      on('ready', &block)
    end

    def on_roster(&block)
      on('roster', &block)
    end

    def on_tick(&block)
      on('tick', &block)
    end

    def on_message(&block)
      on('message', &block)
    end

    def on_timer(time, &block)
      @timer = time

      on('timer', &block)
    end

    def on(event, &block)
      if block_given?
        @callbacks[event.to_s] = block
        self
      else
        @callbacks[event.to_s]
      end
    end

    def start
      if EventMachine.reactor_running?
        connect
      else
        EventMachine.epoll
        EventMachine.kqueue

        EventMachine::run do
          connect
          EventMachine.add_periodic_timer(@timer, @callbacks['timer'])
        end
      end
    end

    def connect
      @connection = OSCAR.connect server, port, uin, password, self
    end

    def method_missing(method, *args, &block)
      p method
      if @callbacks.has_key? method.to_s
        @callbacks[method.to_s].call(*args, @connection)
#      else
#        return super unless @connection.client.respond_to?(method)
#        @connection.client.send(method, *args, &block)
      end
    end

    def respond_to?(method, include_private=false)
      @connection.client.respond_to?(method, include_private) || super(method, include_private)
    end

    # Terminate the currently running Icq and close EventMachine loop
    def stop
      EventMachine.stop_event_loop
      @last_status
    end

    # Close the connection to twitter without closing the eventmachine loop
    def close_connection
      @connection.close_connection if @connection
    end

    def stop_stream
      @connection.stop if @connection
    end

    protected
  end
end
