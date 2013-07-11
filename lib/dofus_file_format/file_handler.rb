module DofusFileFormat
  class FileHandler
    def initialize(file)
      @file = file
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

