require 'bindata'
require 'dofus_file_format/common_types'
require 'dofus_file_format/dynamic_types'
require 'dofus_file_format/file_handler'

module DofusFileFormat
  class Property < BinData::Record
    VECTOR_TYPE = -99
    byte_counted_string :name
    int32be :type
    property :element_type, onlyif: :vector?

    def vector?
      type == VECTOR_TYPE
    end
  end

  class PropertyListEntry < BinData::Record
    endian :big
    byte_counted_string :name
    uint32 :n1
    int32be :type
    uint32 :n3
  end

  class ClassSchema < BinData::Record
    endian :big

    uint32 :class_number
    byte_counted_string :class_name
    byte_counted_string :namespace

    counted_array :properties, type: :property
  end

  class ObjectFileStructure < BinData::Record
    endian :big

    string :magic, read_length: 3
    seek_offset

    byte_counted_hash_table :objects, key_type: :uint32be, value_type: :uint32be

    counted_array :classes, type: :class_schema

    byte_counted_array :all_properties, type: :property_list_entry
    byte_counted_array :all_object_numbers, type: :uint32be

    rest :rest
  end

  class ObjectFile < FileHandler
    def initialize(*arguments)
      super *arguments

      @dynamic_type_manager = DynamicTypeManager.new(@i18n_file)

      @dynamic_type_manager.add_types @data.classes
    end

    def file_structure
      ObjectFileStructure
    end

    def object_name_table
      @object_name_table ||= {}.tap do |table|
        @data.objects.value.each_pair do |object_number, offset|
          object = object_at_offset(offset)
          if object.respond_to? :_nameId
            id = object._nameId.message_number.snapshot
            table[id] = offset
          end
        end
      end
    end

    def object_at_offset(offset)
      read_part(offset, @dynamic_type_manager.object_reader)
    end

    def object_numbered(number)
      object_at_offset @data.objects.value[number]
    end

    def object_named(name)
      object_at_offset object_name_table[i18n_file.number_for_message(name)]
    end

    def i18n_file
      @i18n_file || raise(NotImplementedError, 'You need to initialize with the i18n_file parameter to use this method')
    end
  end
end

