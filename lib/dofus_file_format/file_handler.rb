module DofusFileFormat
  class FileHandler
    attr_reader :data

    def initialize(options)
      options.respond_to? :each_pair or
        raise ArgumentError, 'An option hash is required'

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

    # The @data instance variable is too complex to print
    def pretty_print_instance_variables
      instance_variables - [:@data]
    end
  end
end

