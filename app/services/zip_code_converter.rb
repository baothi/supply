class ZipCodeConverter
  def self.convert(value, state)
    value = value.to_s
    raise 'Invalid Zip Code Passed' if value.blank?

    return value if value.length == 5

    raise 'Can currently only deal with 4 character zipcodes' if value.length != 4

    case state
    when 'Connecticut', 'Massachusetts', 'Maine', 'New Hampshire', 'New Jersey', 'Puerto Rico',
          'Rhode Island', 'Vermont', 'NJ', 'MA', 'ME', 'NH', 'CT', 'RI', 'VT'
      value = "0#{value}"
    else
      value.to_s
    end
    value
  end
end
