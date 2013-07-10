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
    default_parameter structure: nil

    uint32be :byte_count
    string :content, read_length: :byte_count

    def get
      structure = @params[:structure]

      if structure
        BinData::RegisteredClasses.lookup(structure).read content
      else
        content
      end
    end

    def set(v)
      structure = @params[structure]

      if structure
        BinData::RegisteredClasses.lookup(@params[:structure]).new v
      else
        v
      end
    end
  end

  class LengthTaggedString < BinData::Primitive
    uint16be :byte_count
    string :content, read_length: :byte_count

    include StringBasedPrimitive
  end
end

