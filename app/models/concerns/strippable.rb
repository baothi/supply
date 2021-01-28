module Strippable
  extend ActiveSupport::Concern

  def strip_name
    self.name = self.name&.strip
  end

  def strip_presentation
    self.presentation = self.presentation&.strip
  end
end
