module Dropshipper
  class Filter
    def self.apply_filter(contents, _rules)
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
