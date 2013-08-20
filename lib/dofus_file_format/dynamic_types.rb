require 'bindata'
require 'dofus_file_format/i18n_file'

module DofusFileFormat
  class MessageNumber < BinData::Record
    uint32be :message_number
  end

  class AutoFetchingMessageNumber < BinData::Primitive
    mandatory_parameter :i18n

    uint32be :message_number

    def get
      begin
        @params[:i18n].message_numbered(message_number.snapshot)
      rescue ArgumentError
        message_number
      end
    end

    def set(v)
      self.message_number = @params[:i18n].number_for_message v
    end
  end

  class ObjectReader < BinData::BasePrimitive
    mandatory_parameter :dynamic_type_manager

    private
    def dynamic_types
      @params[:dynamic_type_manager].dynamic_types
    end

    def value_to_binary_string(val)
      class_number = dynamic_types.key(val.class)
      class_number or raise ArgumentError,
        'The type must be registered with the DynamicTypeManager'
      BinData::Uint32be.new(class_number).to_binary_s + val.to_binary_s
    end

    def read_and_return_value(io)
      class_number = BinData::Uint32be.read(io)
      dynamic_types[class_number].new.read(io)
    end

    def sensible_default
      nil
    end
  end

  class DynamicTypeManager
    attr_reader :simple_types
    attr_reader :dynamic_types

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
              element_type = [:object_reader, dynamic_type_manager: self]
            else
              raise NotImplementedError, 'Unable to handle type'
            end
            type_arguments = [type: element_type]

          else
            mapped_type = :object_reader
            type_arguments = [dynamic_type_manager: self]
            require 'pry'
            binding.pry
          end

          [mapped_type, property_name, *type_arguments]
        end

        @dynamic_types[specification.class_number.value] =
          BinData::Struct.new name: type_name, fields: fields
      end
    end

    def object_reader
      @object_reader = ObjectReader.new dynamic_type_manager: self
    end
  end
end

