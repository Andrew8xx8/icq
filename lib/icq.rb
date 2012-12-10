require "icq/version"
require "icq/string"
require 'eventmachine'

module Icq
  autoload 'OSCAR', 'icq/oscar'
  autoload 'Listener', 'icq/listener'

  autoload 'SSI', 'icq/oscar/ssi'
  autoload 'BuddyList', 'icq/oscar/buddy_list'
  autoload 'Admin', 'icq/oscar/admin'
  autoload 'DebugColored', 'icq/oscar/debug_colored'
  autoload 'Generic', 'icq/oscar/generic'
  autoload 'IcqMeta', 'icq/oscar/icq_meta'
  autoload 'SSI', 'icq/oscar/ssi'
  autoload 'Auth', 'icq/oscar/auth'
  autoload 'BytesHelper', 'icq/oscar/bytes_helper'
  autoload 'Connection', 'icq/oscar/connection'
  autoload 'DebugNil', 'icq/oscar/debug_null'
  autoload 'ICBM', 'icq/oscar/icbm'
  autoload 'Location', 'icq/oscar/location'

  def self.connect
    EM.run do
      # Create your name-password
      uin, password = '609241916', 'Q0sxqiyg'
      listener = Listener.new
p listener
      client = OSCAR.connect uin, password, listener
      listener.client = client
    end
  end
end
