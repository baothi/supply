module Spree
  class RetailerOrderReport < ApplicationRecord
    belongs_to :retailer
    belongs_to :supplier

    scope :generated_today, -> {
      generated_on(DateTime.now)
    }

    scope :generated_on, ->(datetime) {
      month = datetime.month
      year = datetime.year
      day = datetime.day
      query = 'extract(day from report_generated_at) = ? '\
        'AND extract(month from report_generated_at) = ?'\
        'AND extract(year from report_generated_at) = ?'
      where(query, day, month, year)
    }
  end
end
