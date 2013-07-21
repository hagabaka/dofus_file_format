require 'bindata'
require 'dofus_file_format/common_types'
require 'dofus_file_format/file_handler'
require 'unicode'

module DofusFileFormat
  class MessageEntry < BinData::Record
    endian :big

    uint8 :normalization_form_specified
    uint32 :message_offset
    uint32 :normalization_form_offset, onlyif: :normalization_form_specified?

    def normalization_form_specified?
      normalization_form_specified.nonzero?
    end
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

  class I18nFileStructure < BinData::Record
    seek_offset
    byte_counted_hash_table :messages, key_type: :uint32be, value_type: :message_entry
    byte_counted_hash_table :keyed_messages,
      key_type: :byte_counted_string, value_type: :uint32be
    byte_counted_array :sorted_message_numbers, type: :uint32be
    rest :rest
  end

  class I18nFile < FileHandler
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
      entry = @data.messages.value[number]
      raise ArgumentError, 'Not a message number' unless entry

      if normalized
        offset =
          if entry.normalization_form_specified?
            entry.normalization_form_offset
          else
            entry.message_offset
          end
        Unicode.downcase(message_at_offset(offset))
      else
        message_at_offset(entry.message_offset)
      end
    end

    def message_keyed(key)
      message_at_offset(@data.keyed_messages.value[key])
    end

    def sorted_message_numbers
      @data.sorted_message_numbers.to_a
    end

    def number_for_message(message)
      sorted_message_numbers.bsearch do |number|
        Unicode.strcmp Unicode.downcase(message), message_numbered(number, true)
      end
    end
  end
end

