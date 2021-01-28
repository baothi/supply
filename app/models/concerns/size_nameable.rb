module SizeNameable
  extend ActiveSupport::Concern

  def combined_size_name(first_name, second_name)
    if first_name.present? && second_name.present?
      "#{first_name} #{second_name}"
    elsif first_name.present?
      "#{first_name}"
    else
      raise 'Invalid Scenario deriving combined size name'
    end
  end
end
