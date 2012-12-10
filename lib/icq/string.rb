  class String
    def unpack! template
      array = unpack template
      length = array.pack(template).length
      slice! 0...length
      array
    end
  end
