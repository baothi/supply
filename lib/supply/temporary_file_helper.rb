module Supply
  class TemporaryFileHelper
    def self.temp_file(contents, extension)
      # What you want the tempfile filename to start with
      name_start = "#{DateTime.now.to_i}"
      # What you want the tempfile filename to end with (probably including an extension)
      # by default, tempfilenames carry no extension
      name_end = ".#{extension}"
      # Where you want the tempfile to live
      location = Rails.root.join('tmp', 'cache')
      # Options for the tempfile (e.g. which encoding to use)
      # TODO: Confirm that this is usable for other file formats
      options = { encoding: Encoding::ASCII_8BIT }
      # Will create a tempfile
      # at /path/to/some/dir/my_special_file_20140224-1234-abcd123.gif
      # (where '20140224-1234-abcd123' represents some unique timestamp & token)
      # with a UTF-8 encoding
      # with the contents 'Hello, tempfile!'
      file = Tempfile.new([name_start, name_end], location, options)
      file.binmode
      file.write contents
      file.rewind
      file
    end
  end
end
