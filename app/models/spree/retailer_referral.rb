class Spree::RetailerReferral < ApplicationRecord
  belongs_to :spree_supplier

  validates :url,
            presence: true,
            http_url: true,
            uniqueness: { scope: :spree_supplier_id,
                          message: 'already exists in your invites.' }

  def self.top_suppliers_with_highest_referrals
    count_hash = Spree::RetailerReferral.
                 group(:spree_supplier_id).
                 order('count(*) desc').
                 limit(5).count

    count_hash.map do |id, count|
      { supplier: Spree::Supplier.find(id), count: count }
    end
  end
end
