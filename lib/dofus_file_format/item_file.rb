require 'dofus_file_format/object_file'

module DofusFileFormat
  class ItemFile < ObjectFile
    def initialize(*arguments)
      super *arguments

      @object_table = {}
      @object_name_table = {}
      @data.objects.each do |entry|
        offset = entry.object_offset
        @object_table[entry.object_number.snapshot] = offset

        object = object_at_offset(offset)
        if object.respond_to? :_nameId
          id = object._nameId.message_number.snapshot
          @object_name_table[id] = offset
        end
      end
    end

    def item_named(name)
      object_at_offset @object_name_table[i18n_file.number_for_message(name)]
    end
  end
end

