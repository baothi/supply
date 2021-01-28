class ResponseObject
  attr_accessor :success
  attr_accessor :message
  attr_accessor :data_object
  attr_accessor :data_object2
  attr_accessor :data_objects
  attr_accessor :success_objects
  attr_accessor :error_objects

  def initialize
    @success = false
    @message = 'N/A'
    @data_object = nil
    @data_objects = []
    @success_objects = []
    @error_objects = []
  end

  def new; end

  def reset_message!
    @message = ''
  end

  def success!
    @success = true
  end

  def success?
    @success == true
  end

  def successful?
    @success == true
  end

  def failure?
    !@success
  end

  def failed?
    failure?
  end

  def fail!
    @success = false
  end

  def failed!
    fail!
  end

  def has_data_object?
    data_object.present?
  end

  def has_data_objects?
    !@data_objects.empty?
  end

  def has_success_objects?
    !@success_objects.empty?
  end

  def num_success_objects
    @success_objects.length
  end

  def has_error_objects?
    !@error_objects.empty?
  end

  def num_error_objects
    @error_objects.length
  end

  # Splat operator expects
  # data_object
  def self.instantiate_response_object(success, message, _opts = {})
    ro = ResponseObject.new
    ro.success = success
    ro.message = message
    ro
  end

  def self.failure_response_object(message, opts = {})
    self.
      instantiate_response_object(false, message, opts)
  end

  def self.success_response_object(message, opts = {})
    self.
      instantiate_response_object(true, message, opts)
  end

  def self.blank_success_response_object
    self.success_response_object('', {})
  end

  def self.blank_failure_response_object
    self.failure_response_object('', {})
  end

  # Takes in an exception
  def fail_with_exception!(ex, log = true)
    puts caller_locations

    caller_method = caller_locations(1..1).first

    self.message = "#{ex}"
    self.success = false
    return unless log

    puts "Issue in #{caller_method}".red
    puts "#{ex}".red
    puts '----------'.red
    puts 'Backtrace'.red
    puts '----------'.red
    puts "#{ex.backtrace}".red
  end
end
