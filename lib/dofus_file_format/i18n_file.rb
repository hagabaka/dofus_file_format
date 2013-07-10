require 'bindata'
require 'dofus_file_format/strings'

module DofusFileFormat
  class I18nTable < BinData::Array
    default_parameter read_until: :eof

    endian :big

    uint32 :message_number
    uint8 :alternate_form_count
    uint32 :message_offset
    array :alternate_form_offsets, type: :uint32, initial_length: :alternate_form_count
  end

  class I18nDictionary < BinData::Array
    default_parameter read_until: :eof

    length_tagged_string :message_key
    uint32be :message_offset
  end

  class I18nNumberList < BinData::Array
    default_parameter read_until: :eof

    uint32be
  end

  class I18nFile < BinData::Record
    uint32be :table_offset
    string :all_messages, read_length: ->{table_offset - 4}
    section :table, structure: :i18n_table
    section :dictionary, structure: :i18n_dictionary
    section :message_numbers, structure: :i18n_number_list

    def message_at_offset(offset, force_utf8=true)
      result = LengthTaggedString.read all_messages[(offset - all_messages.offset)..-1]

      if force_utf8
        result.force_encoding('UTF-8')
      else
        result
      end
    end

    def message_numbered(number)
      pointer = table.find {|entry| entry.message_number == number}
      message_at_offset(pointer.message_offset)
    end

    def message_keyed(key)
      pointer = dictionary.find {|entry| entry.message_key == key}
      message_at_offset(pointer.message_offset)
    end
  end
end

