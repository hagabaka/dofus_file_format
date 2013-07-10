require 'bindata'
require 'dofus_file_format/section'

module DofusFileFormat
  class I18nMessage < BinData::Primitive
    uint16be :byte_count
    string :content, read_length: :byte_count

    include StringBasedPrimitive
  end

  class I18nTable < BinData::Array
    default_parameter read_until: :eof

    endian :big

    uint32 :message_number
    uint8 :alternate_form_count
    uint32 :message_offset
    array :alternate_form_offsets, type: :uint32, initial_length: :alternate_form_count
  end

  class I18nFile < BinData::Record
    array :sections, type: :section, read_until: :eof

    def messages_section
      sections[0]
    end

    def table_section
      sections[1]
    end

    def table
      @table ||= I18nTable.read table_section
    end

    def message_at_offset(offset, force_utf8=true)
      result =
        I18nMessage.read(messages_section.to_s[(offset - messages_section.content.offset)..-1])

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
  end
end

