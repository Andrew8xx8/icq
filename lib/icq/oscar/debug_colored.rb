module Icq
  module OSCAR
    module DebugColored
      HOME = '/root/em-oscar'

      def debug message = nil, &block
        if block_given?
          result = yield

          message = 
            case result
            when Hash
              result.map do |k,v| "#{k} = #{v}" end.join(', ')
            when Array
              result.map do |name| "#{name} = #{eval name, block.binding}" end.join(', ')
            when Symbol
              "#{result} = #{eval result.to_s, block.binding}"
            end
        end
        copy = caller.dup
        copy.shift while copy.first =~ /debug/
          name = copy.first.sub HOME, ''

        if name =~ /send_data/
          message = "\e[0;34m#{message}\e[m"
        elsif name =~ /receive_data/
          message = "\e[0;31m#{message}\e[m"
        end

        puts "\e[0;37m#{name}\e[m: #{message}"
      end
    end
  end
end
