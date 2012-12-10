module Icq
  # Defines constants and methods related to configuration
  module Configuration
    # An array of valid keys in the options hash when configuring TweetStream.
    VALID_OPTIONS_KEYS = [
      :uin,
      :password,
      :server,
      :port
    ].freeze

    # By default, don't set a username
    DEFAULT_UIN = nil

    # By default, don't set a password
    DEFAULT_PASSWORD = nil

    # By default, use login.icq.com
    DEFAULT_SERVER = 'login.icq.com'

    # By default, use standard port
    DEFAULT_PORT = 5190

    # @private
    attr_accessor *VALID_OPTIONS_KEYS

    # When this module is extended, set all configuration options to their default values
    def self.extended(base)
      base.reset
    end

    # Convenience method to allow configuration options to be set in a block
    def configure
      yield self
    end

    # Create a hash of options and their values
    def options
      Hash[*VALID_OPTIONS_KEYS.map {|key| [key, send(key)] }.flatten]
    end

    # Reset all configuration options to defaults
    def reset
      self.uin         = DEFAULT_UIN
      self.password    = DEFAULT_PASSWORD
      self.server      = DEFAULT_SERVER
      self.port        = DEFAULT_PORT
      self
    end
  end
end
