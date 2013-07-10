require 'bindata'

module DofusFileFormat
  module StringBasedPrimitive
    def get
      content
    end

    def set(v)
      self.content = v
    end
  end

  class Section < BinData::Primitive
    uint32be :byte_count
    string :content, read_length: ->{byte_count - 4}

    include StringBasedPrimitive
  end
end

