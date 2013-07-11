require 'bindata'
require 'dofus_file_format/common_types'
require 'ffi-icu'

module DofusFileFormat
  class I18nTableEntry < BinData::Record
    endian :big

    uint32 :message_number
    uint8 :normalization_form_specified
    uint32 :message_offset
    uint32 :normalization_form_offset, onlyif: :normalization_form_specified?

    def normalization_form_specified?
      normalization_form_specified.nonzero?
    end
  end

  class I18nDictionaryEntry < BinData::Record
    byte_counted_string :message_key
    uint32be :message_offset
  end

  class I18nFile < BinData::Record
    uint32be :table_offset
    string :all_messages, read_length: ->{table_offset - 4}
    byte_counted_array :table, type: :i18n_table_entry
    byte_counted_array :dictionary, type: :i18n_dictionary_entry
    byte_counted_array :sorted_message_numbers, type: :uint32be

    def message_at_offset(offset, force_utf8=true)
      result = ByteCountedString.read all_messages[(offset - all_messages.offset)..-1]

      if force_utf8
        result.force_encoding('UTF-8')
      else
        result
      end
    end

    def table_entry_numbered(number)
      table.find {|entry| entry.message_number == number}
    end

    def message_numbered(number, normalized=false)
      pointer = table_entry_numbered(number)
      if normalized
        if pointer.normalization_form_specified?
          message_at_offset(pointer.normalization_form_offset)
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

