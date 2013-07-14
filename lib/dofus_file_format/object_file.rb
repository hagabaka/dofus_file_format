require 'bindata'
require 'dofus_file_format/common_types'
require 'dofus_file_format/file_handler'

module DofusFileFormat
  class TypeTag < BinData::Primitive
    int32be :type_id

    ID_TO_NAME = {
      -5 => :message_number,
      -1 => :integer,
      -2 => :boolean,
      -3 => :string,
      -4 => :double,
      -6 => :unsigned_integer,
      -99 => :vector
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
    property :element_type, onlyif: :vector?

    def vector?
      type == :vector
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

    counted_array :properties, type: :property
  end

  class ObjectEntry < BinData::Record
    endian :big
    uint32 :object_number
    uint32 :object_offset
  end

  class MessageNumber < BinData::Record
    uint32be :message_number
  end

  class ObjectFileStructure < BinData::Record
    endian :big

    string :magic, read_length: 3
    seek_offset

    byte_counted_array :objects, type: :object_entry

    counted_array :classes, type: :class_schema

    byte_counted_array :all_properties, type: :property_list_entry
    byte_counted_array :all_object_numbers, type: :uint32be

    rest :rest
  end

  class ObjectFile < FileHandler
    def initialize(*arguments)
      super *arguments

      @type_mapping = {
        message_number: :message_number,
        integer: :int32be,
        boolean: :uint8,
        string: :byte_counted_string,
        double: :double_be,
        unsigned_integer: :uint32be,
        vector: :uint32be
      }

      if @i18n_file
        @type_mapping[:message_number] = [:auto_fetching_message_number, i18n: @i18n_file]
      end

      @class_structures = {0 => :uint32be}
      @data.classes.sort_by(&:class_number).each do |schema|
        fields = schema.properties.map do |entry|
          name = "_#{entry.name}"
          (mapped_type, *type_arguments) = [* @type_mapping[entry.type.value]]

          if entry.type.value == :vector

            case unmapped_element_type= entry.element_type.type.value
            when *@type_mapping.keys
              element_type = @type_mapping[unmapped_element_type]
            when *@class_structures.keys
              @generic_struct ||= BinData::Struct.new fields:
                [[:uint32be, :class_number],
                 [:choice, :property, choices: @class_structures, selection: :class_number]]
              element_type = @generic_struct
            else
              raise NotImplementedError, 'Unable to handle type'
            end
            mapped_type = :counted_array
            type_arguments = [type: element_type]
          end

          mapped_type or raise NotImplementedError, 'Unable to handle type'

          [mapped_type, name, *type_arguments]
        end

        name = BinData::RegisteredClasses.underscore_name schema.class_name
        @class_structures[schema.class_number] =
          BinData::Struct.new name: name, endian: :big, fields: fields
      end

      @object_table = {}
      @data.objects.each do |entry|
        offset = entry.object_offset
        @object_table[entry.object_number.snapshot] = offset
      end
    end

    def file_structure
      ObjectFileStructure
    end

    def object_name_table
      @object_name_table ||= {}.tap do |table|
        @object_table.each_pair do |object_number, offset|
          object = object_at_offset(offset)
          if object.respond_to? :_nameId
            id = object._nameId.message_number.snapshot
            table[id] = offset
          end
        end
      end
    end

    def object_at_offset(offset)
      class_number = read_part(offset, BinData::Uint32be)
      read_part(offset + 4, @class_structures[class_number])
    end

    def object_numbered(number)
      object_at_offset @object_table[number]
    end

    def object_named(name)
      object_at_offset object_name_table[i18n_file.number_for_message(name)]
    end

    def i18n_file
      @i18n_file || raise(NotImplementedError, 'You need to initialize with the i18n_file parameter to use this method')
    end
  end
end

