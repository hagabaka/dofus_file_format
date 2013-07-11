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

  class ByteCountedArray < BinData::Primitive
    default_parameter type: :uint8be

    uint32be :byte_count
    string :content, read_length: :byte_count

    def get
      BinData::Array.new(type: @params[:type], read_until: :eof).read content
    end

    def set(v)
      array = BinData::Array.new(type: @params[:type])
      array.assign(v)
      self.content = array.to_binary_s
    end
  end

  class ByteCountedString < BinData::Primitive
    uint16be :byte_count
    string :content, read_length: :byte_count

    include StringBasedPrimitive
  end

  class Seek < BinData::Primitive
    mandatory_parameter :offset

    private
    def value_to_binary_string(val)
      ''
    end

    def read_and_return_value(io)
      io.raw_io.seek eval_parameter(:offset), IO::SEEK_SET
      ''
    end

    def sensible_default
      ''
    end
  end

  class SeekOffset < BinData::Record
    uint32be :target
    seek offset: :target
  end
end

