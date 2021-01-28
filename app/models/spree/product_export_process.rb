class Spree::ProductExportProcess < ApplicationRecord
  include AASM
  include IntervalSearchScopes
  include Spree::ProductExportProcesses::StatusStateMachine

  belongs_to :product
  belongs_to :retailer

  validates_presence_of :product
  validates_presence_of :retailer

  def in_progress?
    !['cancelled', 'completed', 'error'].include? self.status
  end

  scope :in_process_of_being_exported, -> {
    in_progress.or(variants_export).or(images_export)
  }

  def append_time(val)
    val = "#{DateTime.now}: #{val}\n"
    val
  end

  def log_activity(content, save_record = false)
    content = append_time(content)
    self.log.nil? ? self.log = content : self.log << content
    save if save_record
  end

  def log_activity!(val)
    log_activity(val, false)
    self.save!
  end

  def log_error(content, save_record = false)
    content = append_time(content)
    self.error_log.nil? ? self.error_log = content : self.error_log << content
    save if save_record
  end

  def log_error!(content)
    log_error(content, false)
    self.save!
  end

  def clear_logs!
    self.log = nil
    self.error_log = nil
    self.save!
  end

  def combined_logs
    'Logs: '\
      "#{log}\n"\
      'Errors: '\
      "#{error_log}"
  end
end
