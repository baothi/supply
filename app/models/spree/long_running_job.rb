module Spree
  class LongRunningJob < ApplicationRecord
    include InternalIdentifiable
    include AASM
    include Spree::LongRunningJobs::StatusStateMachine
    include Spree::LongRunningJobs::Constants
    include Settings::Settingable

    store_accessor :json_option_1, :from_date, :to_date

    belongs_to :user
    belongs_to :retailer
    belongs_to :supplier

    # This is the true owner of the job. The retailer or supplier.
    # :retailer_id & :supplier_id are more so for holding reference values that may be
    # needed to execute the actual job.

    belongs_to :teamable, polymorphic: true

    # We pass the name of the class to initiate & re-instantiate it.
    # This way we don't have to mess around with after commit
    # after_commit :initiate_job

    # Expects an object of type Spree::Retailer or
    # Spree::Supplier
    scope :initiated_by, ->(obj) {
      return unless obj.present?

      where('teamable_type = :klass and teamable_id = :id', klass: obj.class.name, id: obj.id)
    }

    scope :filter, ->(param) {
      return unless param.present?

      send(param)
    }

    has_attached_file :input_csv_file
    has_attached_file :output_csv_file

    valid_file_types = %w(text/plain text/csv application/vnd.ms-excel text/comma-separated-values
                          application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
                          application/octet-stream)

    validates_attachment :input_csv_file, content_type: {
        content_type: [valid_file_types]
    }

    validates_attachment :output_csv_file, content_type: {
        content_type: [valid_file_types]
    }

    setting :attempt_auto_pay, :boolean, default: false
    setting :auto_paid, :boolean, default: false

    def clear_logs!
      self.log = nil
      self.error_log = nil
      self.save
    end

    def initialize_job!
      self.num_of_records_processed = 0
      self.num_of_records_not_processed = 0
      self.num_of_errors = 0
      self.progress = 0
      self.time_started = Time.now
      self.time_completed = nil
      self.completion_time = nil
      self.log = nil
      self.error_log = nil
      self.save!
    end

    def initialize_and_begin_job!
      self.initialize_job!
      self.begin_job!
    end

    def combined_logs
      'Logs: '\
      "#{log}\n"\
      'Errors: '\
      "#{error_log}"
    end

    def self.build_new_shopify_order_import
      job = Spree::LongRunningJob.new
      job.action_type = Spree::LongRunningJob::IMPORT
      job.job_type = Spree::LongRunningJob::ORDERS_IMPORT
      job.initiated_by = Spree::LongRunningJob::SYSTEM
      job
    end

    def self.build_new_shopify_order_import!
      job = build_new_shopify_order_import
      job.save!
      job
    end

    def update_status(status)
      status ? self.num_of_records_processed += 1 : self.num_of_records_not_processed += 1
      total = self.num_of_records_not_processed + self.num_of_records_processed
      self.progress = (total.to_f / self.total_num_of_records) * 100
      if self.progress == 100
        self.complete_job if self.may_complete_job?
        self.time_completed = DateTime.now
        self.completion_time = self.time_completed - self.time_started
      end
      self.save!
    end

    def log_error(content)
      return if content.blank?

      self.error_log.nil? ? self.error_log = content : self.error_log << content
      self.save
    end

    def update_log(content)
      return if content.blank?

      self.log.nil? ? self.log = content : self.log << content
      self.save
    end

    def mark_job_as_complete!
      self.progress == 100
      self.complete_job!
      self.save!
    end
  end
end
