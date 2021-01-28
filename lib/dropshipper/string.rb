class String
  def alpha?
    !!match(/^[[:alnum:]\s]+$/)
  end

  def alpha_numeric?
    !!match(/^[[:alnum:]\s]+$/)
  end

  def validate(string)
    !string.match(/\A[a-zA-Z0-9]*\z/).nil?
  end

  def alpha_with_dashes?
    !!match(/^[[:alnum:]\-\s]+$/)
  end

  def number_only?
    !!match(/^(?<num>\d+)$/)
  end

  def letters_only?
    !!match(/^[[:alpha:]]+$/)
  end

  def propercase
    self.humanize.gsub(/\b('?[a-z])/) { $1.capitalize }
  end

  def alternate_case
    self.chars.each_with_index.map { |c, i| (i % 2).zero? ? c.downcase : c.upcase }.join
  end
end
