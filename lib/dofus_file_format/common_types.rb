require 'bindata'

module DofusFileFormat
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

  class ByteCountedHashTable < BinData::Primitive
    mandatory_parameter :key_type
    mandatory_parameter :value_type

    uint32be :byte_count
    string :content, read_length: :byte_count

    def pair_type
      @pair ||= BinData::Struct.new fields: [[@params[:key_type], :key_field],
                                             [@params[:value_type], :value_field]]
    end

    def get
      pairs = BinData::Array.new(type: pair_type, read_until: :eof).read content
      Hash[pairs.map {|pair| [pair.key_field.snapshot, pair.value_field]}]
    end

    def set(v)
      pairs = Hash.each_pair.map {|key, value| pair_type.new key_field: key, value_field: value}
      self.content = BinData::Array.new(type: pair_type).assign(pairs).to_binary_s
      self.byte_count = self.content.num_bytes
    end
  end

  class CountedArray < BinData::BasePrimitive
    mandatory_parameter :type

    private
    def value_to_binary_string(val)
      BinData::Uint32be.new(val.length).to_binary_s + val.map(&:to_binary_s).join
    end

    def read_and_return_value(io)
      length = BinData::Uint32be.read io
      type = @params[:type]
      unless type.respond_to? :read
        type = BinData::RegisteredClasses.lookup(type)
      end
      Array.new(length) {type.new.read io}
    end

    def sensible_default
      []
    end
  end

  class ByteCountedString < BinData::Primitive
    uint16be :byte_count
    string :content, read_length: :byte_count

    def get
      content.snapshot
    end

    def set(v)
      self.content = v
    end
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

