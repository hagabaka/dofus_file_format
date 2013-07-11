require 'bindata'
require 'dofus_file_format/strings'
require 'ffi-icu'

module DofusFileFormat
  class I18nTable < BinData::Array
    default_parameter read_until: :eof

    endian :big

    uint32 :message_number
    uint8 :normalized_form_count
    uint32 :message_offset
    array :normalized_form_offsets, type: :uint32, initial_length: :normalized_form_count
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
    section :sorted_message_numbers, structure: :i18n_number_list

    def message_at_offset(offset, force_utf8=true)
      result = LengthTaggedString.read all_messages[(offset - all_messages.offset)..-1]

      if force_utf8
        result.force_encoding('UTF-8')
      else
        result
      end
    end

    def message_numbered(number, normalized=false)
      pointer = table.find {|entry| entry.message_number == number}
      if normalized
        if pointer.normalized_form_count > 0
          message_at_offset(pointer.normalized_form_offsets[0])
        else
          message_at_offset(pointer.message_offset).downcase
        end
      else
        message_at_offset(pointer.message_offset)
      end
    end

    def message_keyed(key)
      pointer = dictionary.find {|entry| entry.message_key == key}
      message_at_offset(pointer.message_offset)
    end

    def number_for_message(message)
      sorted_message_numbers.to_a.bsearch do |number|
        message_numbered(number, true) >= ICU::Normalization.normalize(message, 2).downcase
      end
    end
  end
end

