module Icq
  module OSCAR
    include SSI
    include BuddyList
    include Admin
    include DebugColored
    include Generic
    include IcqMeta
    include SSI
    include Auth
    include BytesHelper
    include Connection
    include DebugNil
    include ICBM
    include Location

    attr_accessor :listener, :local_host

    def self.connect *args
      p self
      # TODO async dns
      EM.connect 'login.icq.com', 5190, self, *args
      # rescue Exception
      # resolving exception
    end

    def initialize username, password, listener
      @username, @password, @listener = username, password, listener

      @multiresponse_data = {}
    end

  end
end
