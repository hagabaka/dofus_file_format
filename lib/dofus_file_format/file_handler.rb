module DofusFileFormat
  class FileHandler
    def initialize(options)
      options.each_pair do |key, value|
        instance_variable_set :"@#{key}", value
      end

      @options = options

      unless @file
        raise ArgumentError, 'The file parameter is required'
      end
      @data = file_structure.read @file
    end

    def file_structure
      raise NotImplementedError,
        'FileHandler subclasses must implement the "file_structure" method'
    end

    def read_part(offset, structure)
      @file.seek offset, IO::SEEK_SET
      structure.read @file
    end
  end
end

