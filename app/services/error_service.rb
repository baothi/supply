# Service class for centralizing outputting errors
# level: :error, :warning, :info
class ErrorService
  attr_accessor :exception, :console, :level
  def initialize(exception:, console: true, level: :error)
    @exception = exception
    @console = console
    @level = level
  end

  def perform
    if console
      puts "#{exception}".red
      puts "#{exception.backtrace}".red
    end

    return if Rails.env.development?

    case level
    when :error
      Rollbar.error(exception)
    when :warning
      Rollbar.warning(exception)
    else
      Rollbar.error(exception)
    end
  end
end
