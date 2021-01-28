module Spree::Products::MarketplaceCompliance
  extend ActiveSupport::Concern
  include CommitWrap
  include Spree::ProductsAndVariants::Compliantable

  def run_submission_compliance_check
    ensure_name_compliance
    ensure_description_compliance
    ensure_images_compliance

    # Shipping Category
    ensure_has_shipping_category

    run_compliance_on_all_variants!
    # ensure_at_least_one_variant
    # ensure_at_least_one_variant_that_is_compliant
  end

  def run_marketplace_compliance_check
    # We manually add compliance issue when not submission compalint
    add_marketplace_compliance_issue('Product is not compliant.') if
        has_submission_compliance_errors?
  end

  class_methods do
    def update_all_cached_compliance_status_info!(start,
                                                  finish,
                                                  batch_size = 250,
                                                  supplier_id = nil)
      ro = ResponseObject.blank_success_response_object
      begin
        raise 'Finish must be larger than start value' if start > finish

        num_batches = ((finish - start) / batch_size.to_f).ceil
        current_start = start
        current_finish = start + batch_size

        (1..num_batches).each do |batch_num|
          # Create Job
          ActiveRecord::Base.transaction do
            job = cache_update_job(current_start, current_finish, batch_num, supplier_id)
            execute_after_commit do
              ::Products::ProductComplianceStatusUpdateJob.perform_later(job.internal_identifier)
              puts 'Queued da job'.blue
            end
          end

          # Now line up remaining
          current_start = current_finish
          current_finish = current_finish + batch_size

          # Limit upper bound
          if current_finish >= finish
            current_finish = finish
          end
        end
        ro.message = 'Successfully queued jobs to calculate updated compliance cache information'
      rescue => ex
        ro.fail_with_exception!(ex)
      end
      ro
    end

    def cache_update_job(start, finish, batch_num, supplier_id)
      Spree::LongRunningJob.create(
        action_type: 'import',
        job_type: 'cache_update',
        initiated_by: 'user',
        option_1: start,
        option_2: finish,
        option_3: batch_num,
        supplier_id: supplier_id
      )
    end
  end

  def ensure_name_compliance
    add_submission_compliance_issue('Name is required') if self.name.blank?
  end

  def ensure_description_compliance
    add_submission_compliance_issue(I18n.t('products.compliance.description_required')) if
        self.description.blank?
  end

  def ensure_images_compliance
    add_submission_compliance_issue(I18n.t('products.compliance.requires_images')) unless
        self.has_images?
  end

  # Ensure there's at least one variant?
  def ensure_at_least_one_variant
    add_submission_compliance_issue(I18n.t('products.compliance.requires_one_variant')) if
        self.available_and_submission_compliant_variants.count < 1
  end

  def ensure_has_shipping_category
    return if self.shipping_method.present?

    add_submission_compliance_issue('Product must have Shipping Category')
  end

  # Go through each variant and ensure that its fit for export
  #
  # Has Images
  # Has Unique SKUs
  # Has color/size/category
  # Has platform color/platform size/platform category

  def run_compliance_on_all_variants!
    ActiveRecord::Base.no_touching do
      self.variants.not_discontinued.each(&:update_product_compliance_status!)

      # Return if at least one variant is cool. That's all we need for approval
      count = self.available_and_submission_compliant_variants.count
      return if
          count.positive?

      # If there are no variants
      if count.zero?
        add_submission_compliance_issue(
          I18n.t('products.compliance.requires_one_variant')
        )
        return
      end

      # Report on the problematic variants
      self.available_and_not_submission_compliant_variants.each do |v|
        add_submission_compliance_issue("Variant Issue: #{v.submission_compliance_log}")
      end
    end
  end

  def eligible_for_approval?
    run_submission_compliance_check
    run_marketplace_compliance_check
    does_not_have_submission_compliance_errors? &&
      does_not_have_marketplace_compliance_errors?
  end

  # Only call this after first calling eligible_for_approval?
  # so that the errors can get populated
  # otherwise this will be empty!
  def eligibility_reasoning
    friendly_compliance_errors
  end
end
