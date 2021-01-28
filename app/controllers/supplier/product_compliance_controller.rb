class Supplier::ProductComplianceController < Supplier::BaseController
  def index
    @statuses = %i(
        without_images
        marketplace_compliant
        submission_compliant
        pending_review
    )

    # marketplace_compliant_and_approved
    @products = current_supplier.products.page(params[:page]).per(10).filter(params[:filter_by])
  end
end
