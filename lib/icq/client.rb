module Icq
  class Client

    OPTION_CALLBACKS = [:delete,
                        :scrub_geo,
                        :limit,
                        :error,
                        :enhance_your_calm,
                        :unauthorized,
                        :reconnect,
                        :inited,
                        :direct_message,
                        :timeline_status,
                        :anything,
                        :no_data_received,
                        :status_withheld,
                        :user_withheld].freeze unless defined?(OPTION_CALLBACKS)

    # @private
    attr_accessor *Configuration::VALID_OPTIONS_KEYS
    attr_accessor :options
    attr_reader :control_uri, :control, :stream

    # Creates a new API
    def initialize(options={})
      self.options = options
      merged_options = Icq.options.merge(options)
      Configuration::VALID_OPTIONS_KEYS.each do |key|
        send("#{key}=", merged_options[key])
      end
      @callbacks = {}

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
      if @callbacks.has_key? method.to_s
        @callbacks[method.to_s].call(*args, self)
      else
        return super unless @connection.respond_to?(method)
        @connection.send(method, *args, &block)
      end
    end

    def respond_to?(method, include_private=false)
      @callbacks.has_key method 
      @connection.respond_to?(method, include_private) || super(method, include_private)
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

    def normalize_filter_parameters(query_parameters = {})
      [:follow, :track, :locations].each do |param|
        if query_parameters[param].kind_of?(Array)
          query_parameters[param] = query_parameters[param].flatten.collect { |q| q.to_s }.join(',')
        elsif query_parameters[param]
          query_parameters[param] = query_parameters[param].to_s
        end
      end
      query_parameters
    end

    # A utility method used to invoke callback methods against the Client
    def invoke_callback(callback, *args)
      callback.call(*args) if callback
    end

    def yield_message_to(procedure, message)
      # Give the block the option to receive either one
      # or two arguments, depending on its arity.
      if procedure.is_a?(Proc)
        case procedure.arity
        when 1 then invoke_callback(procedure, message)
        when 2 then invoke_callback(procedure, message, self)
        end
      end
    end

    def connection_options(path, options)
      warn_if_callbacks(options)

      callbacks = @callbacks.dup
      OPTION_CALLBACKS.each do |callback|
        callbacks.merge(callback.to_s => options.delete(callback)) if options[callback]
      end

      inited_proc             = options.delete(:inited)                  || @callbacks['inited']
      extra_stream_parameters = options.delete(:extra_stream_parameters) || {}

      stream_params = {
        :path       => path,
        :method     => (options.delete(:method) || 'get').to_s.upcase,
        :user_agent => user_agent,
        :on_inited  => inited_proc,
        :params     => normalize_filter_parameters(options)
      }.merge(extra_stream_parameters).merge(auth_params)

      [stream_params, callbacks]
    end

    def warn_if_callbacks(options={})
      if OPTION_CALLBACKS.select { |callback| options[callback] }.size > 0
        Kernel.warn("Passing callbacks via the options hash is deprecated and will be removed in Icq 3.0")
      end
    end
  end
end
