require 'bindata'
require 'dofus_file_format/common_types'
require 'dofus_file_format/file_handler'

module DofusFileFormat
  class TypeTag < BinData::Primitive
    uint32be :type_id

    ID_TO_NAME = {
      0xff_ff_ff_fb => :message_number,
      0xff_ff_ff_ff => :integer,
      0xff_ff_ff_fe => :boolean,
      0xff_ff_ff_fd => :criteria,
      0xff_ff_ff_fc => :price,
      0xff_ff_ff_fa => :array,
      0xff_ff_ff_9d => :extended
    }
    NAME_TO_ID = ID_TO_NAME.invert

    def get
      ID_TO_NAME[type_id] || type_id
    end

    def set(v)
      self.type_id = NAME_TO_ID[v] || v
    end
  end

  class Property < BinData::Record
    byte_counted_string :name
    type_tag :type
    property :extended_type, onlyif: :extended_type?

    def extended_type?
      type == :extended
    end
  end

  class PropertyListEntry < BinData::Record
    endian :big
    byte_counted_string :name
    uint32 :n1
    type_tag :type
    uint32 :n3
  end

  class ClassSchema < BinData::Record
    endian :big

    uint32 :class_number
    byte_counted_string :class_name
    byte_counted_string :namespace

    uint32 :property_count
    array :properties, type: :property, initial_length: :property_count
  end

  class ObjectEntry < BinData::Record
    endian :big
    uint32 :object_number
    uint32 :object_offset
  end

  class MessageNumber < BinData::Record
    uint32be :message_number
  end

  class CountedIntArray < BinData::Primitive
    endian :big
    uint32 :element_count
    array :elements, type: :uint32, initial_length: :element_count

    def get
      elements
    end

    def set(v)
      self.count = v.length
      self.elements = v
    end
  end

  class ObjectFileStructure < BinData::Record
    endian :big

    string :magic, read_length: 3
    seek_offset

    byte_counted_array :objects, type: :object_entry

    uint32 :class_count
    array :classes, type: :class_schema, initial_length: :class_count

    byte_counted_array :all_properties, type: :property_list_entry
    byte_counted_array :all_object_numbers, type: :uint32be

    rest :rest
  end

  class ObjectFile < FileHandler
    def initialize(*arguments)
      super *arguments

      @type_mapping = {
        message_number: :message_number,
        integer: :uint32,
        boolean: :uint8,
        criteria: :byte_counted_string,
        price: [:array, type: :uint8, initial_length: 8],
        array: :counted_int_array,
        extended: :counted_int_array
      }

      if @i18n_file
        @type_mapping[:message_number] = [:auto_fetching_message_number, i18n: @i18n_file]
      end

      @class_structures = {}
      @data.classes.each do |schema|
        name = BinData::RegisteredClasses.underscore_name schema.class_name
        fields = schema.properties.map do |entry|
          name = "_#{entry.name}"
          (mapped_type, *arguments) = [* @type_mapping[entry.type.value]]
          [mapped_type, name, *arguments]
        end

        @class_structures[schema.class_number] =
          BinData::Struct.new endian: :big, fields: fields
      end
    end

    def file_structure
      ObjectFileStructure
    end

    def object_at_offset(offset)
      class_number = read_part(offset, BinData::Uint32be)
      read_part(offset + 4, @class_structures[class_number])
    end

    def object_numbered(number)
      object_at_offset @object_table[number]
    end

    def i18n_file
      @i18n_file || raise(NotImplementedError, 'You need to initialize with the i18n_file parameter to use this method')
    end
  end
end
