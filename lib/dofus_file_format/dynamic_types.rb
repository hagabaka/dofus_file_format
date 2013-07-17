require 'bindata'
require 'dofus_file_format/i18n_file'

module DofusFileFormat
  class DynamicTypeManager
    attr_reader :simple_types

    def initialize(i18n_file=nil)
      message_number_type =
        if i18n_file
          [:auto_fetching_message_number, i18n: i18n_file]
        else
          :message_number
        end

      @simple_types = {
        -5 => message_number_type,
        -1 => :int32be,
        -2 => :uint8,
        -3 => :byte_counted_string,
        -4 => :double_be,
        -6 => :uint32be,
      }

      @dynamic_types = {}
    end

    def type_mapping
      @simple_types.merge @dynamic_types
    end

    def object_reader
      @object_reader ||= update_object_reader
    end

    def update_object_reader
      dynamic_types = @dynamic_types

      @object_reader = Class.new(BinData::Primitive) do
        uint32be :type_number

        choice :object, choices: dynamic_types, selection: :type_number

        define_method(:get) {object}

        define_method(:set) {|v| self.object = v}
      end
    end

    def add_types(type_specifications)
      type_specifications.sort_by(&:class_number).each do |specification|
        type_name = specification.class_name

        fields = specification.properties.map do |entry|
          property_name = "_#{entry.name}"
          type_arguments = []
          unmapped_type = entry.type.value

          if @simple_types.has_key? unmapped_type
            mapped_type, *type_arguments = *@simple_types[entry.type.value]

          elsif entry.vector?
            mapped_type = :counted_array
            unmapped_element_type = entry.element_type.type.value
            if @simple_types.has_key? unmapped_element_type
              element_type = @simple_types[unmapped_element_type]
            elsif @dynamic_types.has_key? unmapped_element_type
              element_type = object_reader
            else
              raise NotImplementedError, 'Unable to handle type'
            end
            type_arguments = [type: element_type]

          else
            mapped_type = object_reader

          end

          [mapped_type, property_name, *type_arguments]
        end

        @dynamic_types[specification.class_number.value] =
          BinData::Struct.new name: type_name, fields: fields
      end

      update_object_reader
    end
  end
end

