require 'bindata'
require 'dofus_file_format/common_types'
require 'dofus_file_format/file_handler'
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
      self.message_number = v
    end
  end

  class I18nFileStructure < BinData::Record
    seek_offset
    byte_counted_array :table, type: :i18n_table_entry
    byte_counted_array :dictionary, type: :i18n_dictionary_entry
    byte_counted_array :sorted_message_numbers, type: :uint32be
  end

  class I18nFile < FileHandler
    def initialize(*arguments)
      super *arguments

      @message_offset = {}
      @normalization_form_offset = {}
      @data.table.each do |entry|
        @message_offset[entry.message_number.value] = entry.message_offset
        if entry.normalization_form_specified?
          @normalization_form_offset[entry.message_number.value] =
            entry.normalization_form_offset
        end
      end

      @key_offset = {}
      @data.dictionary.each do |entry|
        @key_offset[entry.message_key.value] = entry.message_offset
      end
    end

    def file_structure
      I18nFileStructure
    end

    def message_at_offset(offset, force_utf8=true)
      result = read_part(offset, ByteCountedString)

      if force_utf8
        result.force_encoding('UTF-8')
      else
        result
      end
    end

    def message_numbered(number, normalized=false)
      offset = @message_offset[number]
      raise ArgumentError, 'Not a message number' unless offset

      if normalized
        offset = @normalization_form_offset[number] || offset
        message_at_offset(offset).downcase
      else
        message_at_offset(@message_offset[number])
      end
    end

    def message_keyed(key)
      message_at_offset(@key_offset[key])
    end

    def sorted_message_numbers
      @data.sorted_message_numbers.to_a
    end

    def number_for_message(message)
      sorted_message_numbers.bsearch do |number|
        message_numbered(number, true) >= ICU::Normalization.normalize(message, 2).downcase
      end
    end
  end
end

