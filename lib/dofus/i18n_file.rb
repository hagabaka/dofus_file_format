#!/usr/bin/ruby

require 'bindata'
require 'pp'

module Dofus
  module I18n
    module StringBasedPrimitive
      def get
        content
      end

      def set(v)
        self.content = v
      end
    end

    class Section < BinData::Primitive
      uint32be :byte_count
      string :content, read_length: ->{byte_count - 4}

      include StringBasedPrimitive
    end

    class Message < BinData::Primitive
      uint16be :byte_count
      string :content, read_length: :byte_count

      include StringBasedPrimitive
    end

    class Table < BinData::Array
      default_parameter read_until: :eof

      endian :big

      uint32 :message_number
      uint8 :alternate_form_count
      uint32 :message_offset
      array :alternate_form_offsets, type: :uint32, initial_length: :alternate_form_count
    end

    class File < BinData::Record
      array :sections, type: :section, read_until: :eof

      def messages_section
        sections[0]
      end

      def table_section
        sections[1]
      end

      def table
        @table ||= Table.read table_section
      end

      def message_at_offset(offset, force_utf8=true)
        result =
          Message.read(messages_section.to_s[(offset - messages_section.content.offset)..-1])

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
end

