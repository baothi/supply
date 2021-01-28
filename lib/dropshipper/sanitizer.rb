module Dropshipper
  class Sanitizer
    def self.clean_string_value!(contents)
      val = ''
      begin
        val = contents.to_s.parameterize
      rescue => ex
        puts "Issue Converting: #{contents}: #{ex}"
      end
      val
    end
  end
end
