module IntervalSearchScopes
  extend ActiveSupport::Concern

  included do
    scope :within_interval, ->(params) do
      case params[:period]
      when 'all-times'; nil
      when 'today'; created_today
      when 'this-quarter'; created_this_quarter
      when 'last-quarter'; created_last_quarter
      when 'yesterday'; created_yesterday
      when 'last-seven-days'; created_last_seven_days
      when 'last-week'; created_last_week
      when 'custom'; created_within(params[:from], params[:to])
      end
    end

    scope :created_today, -> {
      where("#{table_name}.created_at > ?", Time.current.beginning_of_day)
    }

    scope :created_this_week, -> {
      where("#{table_name}.created_at > ?", Time.current.beginning_of_week)
    }

    scope :created_this_month, -> {
      where("#{table_name}.created_at > ?", Time.current.beginning_of_month)
    }

    scope :created_this_quarter, -> do
      where("#{table_name}.created_at > ?", Time.current.beginning_of_quarter)
    end

    scope :created_last_quarter, -> do
      created_within(
        Time.current.last_quarter.beginning_of_quarter,
        Time.current.last_quarter.end_of_quarter
      )
    end

    scope :updated_within, ->(from, to) do
      from = from.is_a?(String) ? Time.parse(from) : Time.current
      to = to.is_a?(String) ? Time.parse(to) : Time.current

      where("#{table_name}.updated_at >= ? AND #{table_name}.updated_at <= ?", from, to)
    end

    scope :updated_more_than_15_minutes_ago, -> {
      where("#{table_name}.updated_at < ?", Time.now - 15.minutes)
    }

    scope :updated_less_than_15_minutes_ago, -> {
      where("#{table_name}.updated_at > ?", Time.now - 15.minutes)
    }

    scope :created_within, ->(from, to) do
      from = from.is_a?(String) ? Time.parse(from) : Time.current
      to = to.is_a?(String) ? Time.parse(to) : Time.current

      where("#{table_name}.created_at >= ? AND #{table_name}.created_at <= ?", from, to)
    end

    scope :created_yesterday, -> do
      where("DATE(#{table_name}.created_at) = ?", Date.today - 1)
    end

    scope :created_last_seven_days, -> do
      where("#{table_name}.created_at >=?", 1.week.ago)
    end

    scope :created_last_week, -> do
      created_within(
        1.week.ago.beginning_of_week,
        1.week.ago.end_of_week
      )
    end
  end

  def updated_more_than_15_minutes_ago?
    self.updated_at < DateTime.now - 15.minutes
  end

  def updated_less_than_15_minutes_ago?
    self.updated_at > DateTime.now - 15.minutes
  end
end
