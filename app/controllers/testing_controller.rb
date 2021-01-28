class TestingController < ApplicationController
  include CommitWrap

  before_action :testing_allowed?

  def generate_orders
    amount = params[:amount].nil? ? 10 : params[:amount].to_i
    amount = 10000 if amount > 10000
    ActiveRecord::Base.transaction do
      job = Spree::LongRunningJob.create(
        action_type: 'generation',
        job_type: 'order_generation',
        initiated_by: 'system',
        teamable_id: params[:team_id],
        teamable_type: params[:teamable],
        option_1: amount
      )

      execute_after_commit do
        Shopify::OrderGenerationJob.perform_later(job.id)
        redirect_to generation_status_path(job.internal_identifier)
      end
    end
  end

  def generation_status
    @job = Spree::LongRunningJob.find_by(internal_identifier: params[:job_identifier])
    unless @job.option_10.nil?
      @order_numbers = @job.option_10.split(',')
    end
  end

  def sync_shopify_products
    ActiveRecord::Base.transaction do
      job = Spree::LongRunningJob.create(
        action_type: 'import',
        job_type: 'products_import',
        initiated_by: 'system',
        option_1: 100,
        supplier_id: params[:supplier_id],
        teamable_type: 'Spree::Supplier',
        teamable_id: params[:supplier_id]
      )

      execute_after_commit do
        Shopify::DownloadAndCacheProductsWorker.perform_async(job.internal_identifier)
        redirect_to sync_status_path(job.internal_identifier)
      end
    end
  end

  def sync_status
    @job= Spree::LongRunningJob.find_by(internal_identifier: params[:job_identifier])
  end

  private

  def testing_allowed?
    # We will only want to allow these routes for environments used specifically for testing
    # so I think it will be best to use an explicit variable for them rather than just
    # checking for a development environment
    unless ENV['ALLOW_TESTING_ROUTES']
      redirect_to root_url
    end
  end
end
